// エントリーポイント

import express from "express";
import multer from "multer";
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


app.listen(3000, '0.0.0.0', () => {
    console.log("Server running on http://localhost:3000 and http://10.45.0.94:3000");
});
