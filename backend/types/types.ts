// Geminiからのレスポンスの型定義
export interface Result {
    objectName: string;
    molecules: {
        name: string;
        description: string;
        confidence: number;
    }[];
}

// 返却する分子情報の型定義
export interface MoleculeInfo {
  cid: number;
  sdf: string;
}
