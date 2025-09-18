import fetch from "node-fetch";

/**
 * SDF文字列からPubChem CIDを抽出するヘルパー関数
 * @param sdfBlock 単一のSDFデータブロック
 * @returns CID (number) or null
 */
function getCidFromSdf(sdfBlock: string): number | null {
    const match = sdfBlock.match(/> <PUBCHEM_COMPOUND_CID>\n(\d+)/);
    return match && match[1] ? parseInt(match[1], 10) : null;
}

/**
 * 複数のCIDからSDFデータを一括で取得する
 * @param cids 化合物ID(CID)の配列
 * @returns CIDとSDFデータの配列
 */
export async function cidsToSdfs(cids: number[]): Promise<{ cid: number; sdf: string; }[]> {
    if (!cids || cids.length === 0) {
        return [];
    }

    try {
        // 重複を除いてリクエストを効率化
        const uniqueCids = [...new Set(cids)];
        const cidsString = uniqueCids.join(',');
        const sdfUrl = `https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/cid/${cidsString}/SDF`;
        
        const sdfResponse = await fetch(sdfUrl);
        if (!sdfResponse.ok) {
            console.error(`Failed to get SDF for CIDs:`, sdfResponse.statusText);
            return []; // エラー時は空の配列を返す
        }

        const combinedSdf = await sdfResponse.text();

        // 取得したSDFは$$$$で連結されているので分割する
        const sdfBlocks = combinedSdf.trim().split(/\n\$\$\$\$\n?/);

        const results = sdfBlocks.map(block => {
            if (!block) return null;
            const cid = getCidFromSdf(block);
            if (cid) {
                return { cid, sdf: block };
            }
            return null;
        }).filter((item): item is { cid: number; sdf: string; } => item !== null);

        return results;

    } catch (err) {
        console.error(`Error fetching molecule info for CIDs:`, err);
        return [];
    }
}
