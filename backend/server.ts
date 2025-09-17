// エントリーポイント

import express from "express";
import multer from "multer";
import { analyzeImage } from "./gemini/gemini.js";
import type { Result } from "./types/types.js";
import { getMoleculeInfo } from "./pubchem/pubchem.js";
import { cleanupTempFiles, convertSdfToGlb } from "./converter/converter.js";
import { searchCompoundsByElement } from "./gemini/search.js";
import { cidsToSdfs } from "./pubchem/cidtosdf.js";

const app = express();

// JSONリクエストボディをパースするためのミドルウェア
app.use(express.json());

const upload = multer({ storage: multer.memoryStorage() });

// CORS設定
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

app.post("/analyze", upload.single("image"), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No file provided" });
        }

        const analysisResult: Result | null = await analyzeImage(
            req.file.buffer,
            req.file.mimetype
        );

        if (!analysisResult || !analysisResult.molecules || analysisResult.molecules.length === 0) {
            return res.status(404).json({ error: "Could not analyze image or find molecules." });
        }

        const moleculesWithData = await Promise.all(
            analysisResult.molecules.map(async (molecule) => {
                const moleculeInfo = await getMoleculeInfo(molecule.name);
                return {
                    ...molecule,
                    cid: moleculeInfo?.cid ?? null,
                    sdf: moleculeInfo?.sdf ?? null,
                };
            })
        );

        res.json({
            object: analysisResult.objectName,
            molecules: moleculesWithData,
        });

    } catch (e) {
        console.error(e);
        res.status(500).json({ error: "Analysis failed" });
    }
});

// SDFデータ(text/plain)を受け取り、GLBファイルを返すエンドポイント
app.post("/convert", express.text({ type: 'text/plain', limit: '1mb' }), async (req, res) => {
    const sdfData = req.body;
    if (typeof sdfData !== 'string' || !sdfData) {
        return res.status(400).json({ error: "SDF data (string) is required" });
    }

    let glbPath: string | undefined;
    try {
        glbPath = await convertSdfToGlb(sdfData);

        res.download(glbPath, 'molecule.glb', async (err) => {
            // 送信後に一時ファイルを削除
            await cleanupTempFiles([glbPath!]);
            if (err) {
                console.error('Error sending file:', err);
            }
        });

    } catch (error) {
        console.error('Request to /convert failed:', error);
        if (!res.headersSent) {
            res.status(500).json({ error: 'Failed to convert SDF to GLB' });
        }
        // エラー時にもクリーンアップを試みる
        if (glbPath) {
            await cleanupTempFiles([glbPath]);
        }
    }
});

// 日本語・ひらがなの元素名と元素記号の対応表
const elementSymbolMap: { [key: string]: string } = {
    'すいそ': 'H', '水素': 'H',
    'ヘリウム': 'He',
    'リチウム': 'Li',
    'ベリリウム': 'Be',
    'ほうそ': 'B', 'ホウ素': 'B',
    'たんそ': 'C', '炭素': 'C',
    'ちっそ': 'N', '窒素': 'N',
    'さんそ': 'O', '酸素': 'O',
    'ふっそ': 'F', 'フッ素': 'F',
    'ネオン': 'Ne',
    'ナトリウム': 'Na',
    'マグネシウム': 'Mg',
    'アルミニウム': 'Al',
    'けいそ': 'Si', 'ケイ素': 'Si',
    'りん': 'P', 'リン': 'P',
    'いおう': 'S', '硫黄': 'S',
    'えんそ': 'Cl', '塩素': 'Cl',
    'アルゴン': 'Ar', 'あるごん': 'Ar',
    'カリウム': 'K',
    'カルシウム': 'Ca',
    'てつ': 'Fe', '鉄': 'Fe',
    'どう': 'Cu', '銅': 'Cu',
    'あえん': 'Zn', '亜鉛': 'Zn',
    'ぎん': 'Ag', '銀': 'Ag',
    'きん': 'Au', '金': 'Au',
    'なまり': 'Pb', '鉛': 'Pb',
    'ヨウ素': 'I', 'ようそ': 'I', 'ヨウソ': 'I',
};

// バリデーション用に、有効な入力（日本語名、ひらがな、元素記号の大文字・小文字）のセットを作成
const validInputs = new Set<string>(Object.keys(elementSymbolMap));
Object.values(elementSymbolMap).forEach(symbol => {
    validInputs.add(symbol);
    validInputs.add(symbol.toLowerCase());
});

// 元素記号による化合物検索エンドポイント
app.get("/search", async (req, res) => {
    const userInput = (req.query.element as string) || '';

    // デバッグ用に受け取った値をログに出力
    console.log(`[Search Endpoint] Received userInput: '${userInput}'`);

    if (!userInput) {
        return res.status(400).json({ error: "Query parameter 'element' is required." });
    }

    // 入力値のバリデーション
    if (!validInputs.has(userInput.toLowerCase())) {
        return res.status(400).json({ error: `Invalid element query: '${userInput}'. Please provide a valid element name or symbol.` });
    }

    // ユーザーの入力を元素記号に変換（小文字化してマップを引く）
    const elementSymbol = elementSymbolMap[userInput.toLowerCase()] || userInput.toUpperCase();

    try {
        const compounds = await searchCompoundsByElement(elementSymbol);
        // 成功した場合は配列を直接返す
        res.json(compounds);
    } catch (e) {
        // searchCompoundsByElement内でエラーが発生した場合
        console.error(`Search failed for element '${elementSymbol}':`, e);
        res.status(500).json({ error: "An internal server error occurred during the search." });
    }
});

// 複数のCIDを含むオブジェクト配列を受け取り、それぞれにSDFデータを付与して返すエンドポイント
app.post("/cidtosdf", async (req, res) => {
    const requestData = req.body;

    // リクエストボディが配列であるかを検証
    if (!Array.isArray(requestData)) {
        return res.status(400).json({ error: "Request body must be an array of objects." });
    }

    // 配列からCIDのみを抽出（nullやundefinedのcidは除外）
    const cids = requestData
        .map(item => item.cid)
        .filter((cid): cid is number => cid != null && typeof cid === 'number');

    if (cids.length === 0) {
        // CIDが含まれていない場合は、元のデータをそのまま返すか、エラーを返すか選択できます。
        // ここでは元のデータをそのまま返します。
        return res.json(requestData);
    }

    try {
        // SDFデータを一括取得
        const sdfResults = await cidsToSdfs(cids);

        // 取得したSDFをCIDをキーにしたMapに変換し、高速に検索できるようにする
        const sdfMap = new Map(sdfResults.map(item => [item.cid, item.sdf]));

        // 元のデータにSDFをマージ
        const responseData = requestData.map(item => {
            const sdf = sdfMap.get(item.cid);
            return {
                ...item,
                sdf: sdf || null, // SDFが見つからなかった場合はnullを設定
            };
        });

        res.json(responseData);

    } catch (error) {
        console.error(`Error in /cidtosdf endpoint:`, error);
        res.status(500).json({ error: "An internal server error occurred while fetching SDF data." });
    }
});

app.listen(3000, '0.0.0.0', () => {
    console.log("Server running on http://localhost:3000 and http://10.45.0.94:3000");
});