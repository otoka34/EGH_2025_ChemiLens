// エントリーポイント
import * as dotenv from 'dotenv';
dotenv.config();

import express from "express";
import multer from "multer";
import { promises as fs } from 'fs';
import { analyzeImage } from "./gemini/gemini.js";
import type { Result } from "./types/types.js";
import { getMoleculeInfo } from "./pubchemi/pubchem.js";
import { cleanupTempFiles, convertSdfToGlb } from "./converter/converter.js";

const app = express();
const upload = multer({ storage: multer.memoryStorage() });

app.post("/analyze", upload.single("image"), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No file provided" });
        }

        console.log("Received file:", {
            originalname: req.file.originalname,
            mimetype: req.file.mimetype,
            size: req.file.size
        });

        // MIMEタイプを修正
        let mimeType = req.file.mimetype;
        if (mimeType === 'application/octet-stream') {
            // ファイル名から推測
            const filename = req.file.originalname || '';
            if (filename.toLowerCase().endsWith('.jpg') || filename.toLowerCase().endsWith('.jpeg')) {
                mimeType = 'image/jpeg';
            } else if (filename.toLowerCase().endsWith('.png')) {
                mimeType = 'image/png';
            } else {
                // デフォルトでJPEGとして扱う
                mimeType = 'image/jpeg';
            }
        }

        console.log("Using MIME type:", mimeType);

        const analysisResult: Result | null = await analyzeImage(
            req.file.buffer,
            mimeType
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
                    formula: molecule.formula || null,
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

// Flutter app用のSDFからGLBバイトデータを返すエンドポイント
app.post("/convert-to-glb", express.text({ type: 'text/plain', limit: '1mb' }), async (req, res) => {
    const sdfData = req.body;
    if (typeof sdfData !== 'string' || !sdfData) {
        return res.status(400).json({ error: "SDF data (string) is required" });
    }

    let glbPath: string | undefined;
    try {
        glbPath = await convertSdfToGlb(sdfData);
        
        // GLBファイルをバイナリデータとして読み込み
        const glbBuffer = await fs.readFile(glbPath);
        
        // レスポンスヘッダーを設定
        res.set({
            'Content-Type': 'application/octet-stream',
            'Content-Length': glbBuffer.length.toString(),
        });
        
        // バイナリデータを送信
        res.send(glbBuffer);
        
        // 送信後に一時ファイルを削除
        await cleanupTempFiles([glbPath]);

    } catch (error) {
        console.error('Request to /convert-to-glb failed:', error);
        if (!res.headersSent) {
            res.status(500).json({ error: 'Failed to convert SDF to GLB' });
        }
        // エラー時にもクリーンアップを試みる
        if (glbPath) {
            await cleanupTempFiles([glbPath]);
        }
    }
});


app.listen(3000, () => {
    console.log("Server running on http://localhost:3000");
});
