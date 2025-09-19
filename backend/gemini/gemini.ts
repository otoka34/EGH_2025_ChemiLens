import { GoogleGenerativeAI } from "@google/generative-ai";
import type { Result } from "../types/types.js";

const apiKey = process.env.GEMINI_API_KEY!;
const genAI = new GoogleGenerativeAI(apiKey);

/**
 * 画像を分析し、写っている物体とそれに含まれる分子を特定する
 * @param imageBuffer 画像のバッファデータ
 * @param mimeType 画像のMIMEタイプ (e.g., "image/jpeg")
 * @returns 分析結果のオブジェクト、またはnull
 */

export async function analyzeImage(imageBuffer: Buffer, mimeType: string): Promise<Result | null> {
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    const prompt = `
        Analyze the provided image.
        1. Identify the main object in the image.
        2. List 5 major chemical compounds contained in that object.

        Return a single JSON object with the following structure:
        {
          "objectName": "<name of the identified object>",
          "molecules": [
            {
              "name": "<The standard chemical name (e.g., 'Caffeine', 'Water').>",
              "formula": "<The chemical formula for the molecule. This is a required field. For example, for Water it is 'H2O', for Caffeine it is 'C8H10N4O2'.>",
              "description": "<First, the Japanese name of the molecule, followed by a newline character, then a description of the substance in Japanese, approximately 20 words long.>",
          ]
        }
        Only return the JSON object, with no other text or markdown formatting.
        In "description" and "confidence" section, you must write them in japanese.
    `;

    const imagePart = {
        inlineData: {
            data: imageBuffer.toString("base64"),
            mimeType: mimeType,
        },
    };

    try {
        const result = await model.generateContent([prompt, imagePart]);
        const response = result.response;
        const text = response.text();

        // クリーンなJSONを抽出
        const jsonMatch = text.match(/\{.*\}/s);
        if (!jsonMatch) {
            console.error("No JSON object found in Gemini response:", text);
            return null;
        }

        const parsed = JSON.parse(jsonMatch[0]);
        return parsed as Result;

    } catch (e) {
        console.error("Failed to analyze image with Gemini", e);
        return null;
    }
}