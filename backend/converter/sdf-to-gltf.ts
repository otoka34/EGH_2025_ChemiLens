import { exec } from 'child_process';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { promisify } from 'util';

const execAsync = promisify(exec);

// ES module環境での__dirnameの取得
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * SDFデータをGLB形式に変換する
 * ChemToolkitやOpen3D-MLを使用して分子構造を3Dモデルに変換
 */
export class SDFToGLTFConverter {
  private static tempDir = path.join(__dirname, '../temp');

  /**
   * 一時ディレクトリを初期化
   */
  static async initTempDir(): Promise<void> {
    try {
      await fs.access(this.tempDir);
    } catch {
      await fs.mkdir(this.tempDir, { recursive: true });
    }
  }

  /**
   * SDFデータをGLBファイルに変換
   */
  static async convertSdfToGlb(sdfData: string): Promise<Buffer> {
    await this.initTempDir();

    const timestamp = Date.now();
    const inputFile = path.join(this.tempDir, `molecule_${timestamp}.sdf`);
    const outputFile = path.join(this.tempDir, `molecule_${timestamp}.glb`);

    try {
      // SDFデータをファイルに書き込み
      await fs.writeFile(inputFile, sdfData, 'utf8');

      // Python スクリプトを実行してSDFからGLBに変換
      await this.runPythonConverter(inputFile, outputFile);

      // 生成されたGLBファイルを読み込み
      const glbBuffer = await fs.readFile(outputFile);
      
      return glbBuffer;
    } finally {
      // 一時ファイルを削除
      await this.cleanupFiles([inputFile, outputFile]);
    }
  }

  /**
   * Python変換スクリプトを実行
   */
  private static async runPythonConverter(inputFile: string, outputFile: string): Promise<void> {
    const pythonScript = path.join(__dirname, 'sdf_to_gltf_converter.py');
    
    // Pythonスクリプトが存在しない場合は基本的な変換を実行
    try {
      await fs.access(pythonScript);
      const command = `python3 "${pythonScript}" "${inputFile}" "${outputFile}"`;
      await execAsync(command);
    } catch (error) {
      // Fallback: 基本的な分子構造GLBを生成
      await this.generateBasicMoleculeGLB(inputFile, outputFile);
    }
  }

  /**
   * 基本的な分子構造GLBを生成（フォールバック）
   */
  private static async generateBasicMoleculeGLB(inputFile: string, outputFile: string): Promise<void> {
    try {
      // SDFファイルを解析して原子情報を抽出
      const sdfContent = await fs.readFile(inputFile, 'utf8');
      const atoms = this.parseSDF(sdfContent);

      // 基本的なGLBファイルを生成
      const glbData = await this.createBasicGLB(atoms);
      await fs.writeFile(outputFile, glbData);
    } catch (error) {
      console.error('Failed to generate basic GLB:', error);
      // さらなるフォールバック：固定の小さなGLBファイル
      await this.generateFallbackGLB(outputFile);
    }
  }

  /**
   * SDFファイルから原子情報を抽出
   */
  private static parseSDF(sdfContent: string): Array<{x: number, y: number, z: number, symbol: string}> {
    const lines = sdfContent.split('\n');
    const atoms: Array<{x: number, y: number, z: number, symbol: string}> = [];
    
    // SDF format: 行4以降に原子情報が含まれる
    let atomCount = 0;
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (i === 3) {
        // 原子数を取得
        atomCount = parseInt(line.substring(0, 3));
        continue;
      }
      
      if (i >= 4 && i < 4 + atomCount) {
        // 原子の座標と記号を抽出
        const parts = line.split(/\s+/);
        if (parts.length >= 4) {
          atoms.push({
            x: parseFloat(parts[0]),
            y: parseFloat(parts[1]),
            z: parseFloat(parts[2]),
            symbol: parts[3]
          });
        }
      }
    }
    
    return atoms;
  }

  /**
   * 基本的なGLBファイルを作成
   */
  private static async createBasicGLB(atoms: Array<{x: number, y: number, z: number, symbol: string}>): Promise<Buffer> {
    // 簡単なGLBファイル構造を作成
    // 実際の実装では、glTF/GLBフォーマットに従って適切にエンコードする必要がある
    
    // この例では、基本的な球体を原子の位置に配置するGLBを生成
    const glbData = this.generateSimpleGLB(atoms);
    return glbData;
  }

  /**
   * 簡単なGLBデータを生成（原子を球体として表現）
   */
  private static generateSimpleGLB(atoms: Array<{x: number, y: number, z: number, symbol: string}>): Buffer {
    // 基本的なglTFシーンの構造
    const scene = {
      asset: {
        version: "2.0",
        generator: "ChemiLens Molecule Converter"
      },
      scene: 0,
      scenes: [{ nodes: [0] }],
      nodes: [{
        name: "Molecule",
        mesh: 0
      }],
      meshes: [{
        primitives: [{
          attributes: {
            POSITION: 0,
            NORMAL: 1
          },
          indices: 2
        }]
      }],
      accessors: [
        {
          bufferView: 0,
          componentType: 5126, // FLOAT
          count: atoms.length * 24, // 球体の頂点数（簡略化）
          type: "VEC3"
        },
        {
          bufferView: 1,
          componentType: 5126,
          count: atoms.length * 24,
          type: "VEC3"
        },
        {
          bufferView: 2,
          componentType: 5123, // UNSIGNED_SHORT
          count: atoms.length * 36, // 球体のインデックス数
          type: "SCALAR"
        }
      ],
      bufferViews: [
        {
          buffer: 0,
          byteLength: atoms.length * 24 * 3 * 4, // position data
          target: 34962 // ARRAY_BUFFER
        },
        {
          buffer: 0,
          byteOffset: atoms.length * 24 * 3 * 4,
          byteLength: atoms.length * 24 * 3 * 4, // normal data
          target: 34962
        },
        {
          buffer: 0,
          byteOffset: atoms.length * 24 * 3 * 4 * 2,
          byteLength: atoms.length * 36 * 2, // index data
          target: 34963 // ELEMENT_ARRAY_BUFFER
        }
      ],
      buffers: [{
        byteLength: atoms.length * (24 * 3 * 4 * 2 + 36 * 2)
      }]
    };

    // JSONデータをバイナリデータと組み合わせてGLBファイルを作成
    const jsonStr = JSON.stringify(scene);
    const jsonBuffer = Buffer.from(jsonStr, 'utf8');
    const padding = 4 - (jsonBuffer.length % 4);
    const paddedJsonBuffer = Buffer.concat([jsonBuffer, Buffer.alloc(padding, 0x20)]);

    // バイナリデータ（頂点、法線、インデックス）を生成
    const binaryData = this.generateMoleculeGeometry(atoms);

    // GLBヘッダーを作成
    const header = Buffer.alloc(12);
    header.writeUInt32LE(0x46546C67, 0); // glTF magic
    header.writeUInt32LE(2, 4); // version
    header.writeUInt32LE(12 + 8 + paddedJsonBuffer.length + 8 + binaryData.length, 8); // total length

    // JSONチャンクヘッダー
    const jsonChunkHeader = Buffer.alloc(8);
    jsonChunkHeader.writeUInt32LE(paddedJsonBuffer.length, 0);
    jsonChunkHeader.writeUInt32LE(0x4E4F534A, 4); // JSON chunk type

    // バイナリチャンクヘッダー
    const binaryChunkHeader = Buffer.alloc(8);
    binaryChunkHeader.writeUInt32LE(binaryData.length, 0);
    binaryChunkHeader.writeUInt32LE(0x004E4942, 4); // BIN chunk type

    return Buffer.concat([
      header,
      jsonChunkHeader,
      paddedJsonBuffer,
      binaryChunkHeader,
      binaryData
    ]);
  }

  /**
   * 分子の幾何学データを生成
   */
  private static generateMoleculeGeometry(atoms: Array<{x: number, y: number, z: number, symbol: string}>): Buffer {
    const positions: number[] = [];
    const normals: number[] = [];
    const indices: number[] = [];

    atoms.forEach((atom, atomIndex) => {
      // 原子を球体として表現（簡略化された正八面体）
      const radius = this.getAtomRadius(atom.symbol);
      
      // 簡単な立方体で原子を表現
      const vertices = [
        // 前面
        [-1, -1,  1], [ 1, -1,  1], [ 1,  1,  1], [-1,  1,  1],
        // 後面  
        [-1, -1, -1], [-1,  1, -1], [ 1,  1, -1], [ 1, -1, -1],
      ];
      
      vertices.forEach(([dx, dy, dz]) => {
        positions.push(
          atom.x + dx * radius,
          atom.y + dy * radius, 
          atom.z + dz * radius
        );
        // 法線（簡略化）
        normals.push(dx, dy, dz);
      });

      // インデックス（立方体の面）
      const faces = [
        [0,1,2], [0,2,3], // 前面
        [4,5,6], [4,6,7], // 後面
        [0,4,7], [0,7,1], // 下面
        [2,6,5], [2,5,3], // 上面
        [0,3,5], [0,5,4], // 左面
        [1,7,6], [1,6,2]  // 右面
      ];

      faces.forEach(([a, b, c]) => {
        indices.push(
          atomIndex * 8 + a,
          atomIndex * 8 + b, 
          atomIndex * 8 + c
        );
      });
    });

    const positionBuffer = Buffer.from(new Float32Array(positions).buffer);
    const normalBuffer = Buffer.from(new Float32Array(normals).buffer);
    const indexBuffer = Buffer.from(new Uint16Array(indices).buffer);

    return Buffer.concat([positionBuffer, normalBuffer, indexBuffer]);
  }

  /**
   * 原子の半径を取得（原子記号に基づく）
   */
  private static getAtomRadius(symbol: string): number {
    const radii: { [key: string]: number } = {
      'H': 0.3,   // 水素
      'C': 0.7,   // 炭素
      'N': 0.65,  // 窒素
      'O': 0.6,   // 酸素
      'P': 1.0,   // リン
      'S': 1.0,   // 硫黄
      'F': 0.5,   // フッ素
      'Cl': 0.9,  // 塩素
      'Br': 1.1,  // 臭素
      'I': 1.3    // ヨウ素
    };
    
    return radii[symbol] || 0.8; // デフォルト半径
  }

  /**
   * フォールバック用の基本GLBファイルを生成
   */
  private static async generateFallbackGLB(outputFile: string): Promise<void> {
    // 最小限のGLBファイル（小さな球体）
    const basicGlbData = this.generateSimpleGLB([
      { x: 0, y: 0, z: 0, symbol: 'C' }
    ]);
    
    await fs.writeFile(outputFile, basicGlbData);
  }

  /**
   * ファイルクリーンアップ
   */
  private static async cleanupFiles(files: string[]): Promise<void> {
    await Promise.all(
      files.map(async (file) => {
        try {
          await fs.unlink(file);
        } catch (error) {
          // ファイルが存在しない場合は無視
        }
      })
    );
  }
}