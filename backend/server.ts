// エントリーポイント

import express from "express";
import multer from "multer";
import { analyzeImage } from "./gemini/gemini.js";
import type { Result } from "./types/types.js";
import { getMoleculeInfo } from "./pubchemi/pubchem.js";

const app = express()
const upload = multer({ storage: multer.memoryStorage() });

app.post("/analyze", upload.single("image"), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No file provided" });
        }

        // geminiで画像認識と分子リストの取得
        const analysisResult: Result | null = await analyzeImage(
            req.file.buffer,
            req.file.mimetype
        );

        if (!analysisResult || !analysisResult.molecules || analysisResult.molecules.length === 0) {
            return res.status(404).json({ error: "Could not analyze image or find molecules." });
        }

        // 全ての分子候補に対してCIDとSDFデータを取得
        const moleculesWithData = await Promise.all(
            analysisResult.molecules.map(async (molecule) => {
                const moleculeInfo = await getMoleculeInfo(molecule.name);
                return {
                    ...molecule,
                    cid: moleculeInfo?.cid ?? null,   // CID
                    sdf: moleculeInfo?.sdf ?? null,   // SDF
                };
            })
        );

        res.json({
            object: analysisResult.objectName,
            molecules: moleculesWithData, // CIDとSDFデータ付きの分子リスト
        });
        
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: "Analysis failed" });
    }
});

app.listen(3000, () => {
    console.log("Server running on http://localhost:3000");
});