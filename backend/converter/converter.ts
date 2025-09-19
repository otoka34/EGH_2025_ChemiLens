// converter.ts
import { promises as fs } from 'fs';

// 球を生成する関数
function createSphere(centerX: number, centerY: number, centerZ: number, radius: number, segments: number = 16) {
    const vertices: number[] = [];
    const indices: number[] = [];
    const startIndex = 0;

    // 球の頂点を生成
    for (let lat = 0; lat <= segments; lat++) {
        const theta = (lat * Math.PI) / segments;
        const sinTheta = Math.sin(theta);
        const cosTheta = Math.cos(theta);

        for (let lon = 0; lon <= segments; lon++) {
            const phi = (lon * 2 * Math.PI) / segments;
            const sinPhi = Math.sin(phi);
            const cosPhi = Math.cos(phi);

            const x = centerX + radius * cosPhi * sinTheta;
            const y = centerY + radius * cosTheta;
            const z = centerZ + radius * sinPhi * sinTheta;

            vertices.push(x, y, z);
        }
    }

    // 球のインデックスを生成
    for (let lat = 0; lat < segments; lat++) {
        for (let lon = 0; lon < segments; lon++) {
            const first = startIndex + lat * (segments + 1) + lon;
            const second = first + segments + 1;

            indices.push(first, second, first + 1);
            indices.push(second, second + 1, first + 1);
        }
    }

    return { vertices, indices };
}

// シリンダー（結合）を生成する関数
function createCylinder(x1: number, y1: number, z1: number, x2: number, y2: number, z2: number, radius: number, segments: number = 8) {
    const vertices: number[] = [];
    const indices: number[] = [];

    const dx = x2 - x1;
    const dy = y2 - y1;
    const dz = z2 - z1;
    const length = Math.sqrt(dx * dx + dy * dy + dz * dz);

    if (length < 0.001) return { vertices, indices };

    // 方向ベクトルを正規化
    const dirX = dx / length;
    const dirY = dy / length;
    const dirZ = dz / length;

    // 垂直なベクトルを見つける
    let perpX = 1, perpY = 0, perpZ = 0;
    if (Math.abs(dirX) > 0.9) {
        perpX = 0; perpY = 1; perpZ = 0;
    }

    // 外積で垂直ベクトルを計算
    const upX = perpY * dirZ - perpZ * dirY;
    const upY = perpZ * dirX - perpX * dirZ;
    const upZ = perpX * dirY - perpY * dirX;

    // 正規化
    const upLength = Math.sqrt(upX * upX + upY * upY + upZ * upZ);
    const normalizedUpX = upX / upLength;
    const normalizedUpY = upY / upLength;
    const normalizedUpZ = upZ / upLength;

    // もう一つの垂直ベクトル
    const rightX = dirY * normalizedUpZ - dirZ * normalizedUpY;
    const rightY = dirZ * normalizedUpX - dirX * normalizedUpZ;
    const rightZ = dirX * normalizedUpY - dirY * normalizedUpX;

    const startIndex = 0;

    // シリンダーの頂点を生成
    for (let i = 0; i <= segments; i++) {
        const angle = (i * 2 * Math.PI) / segments;
        const cos = Math.cos(angle);
        const sin = Math.sin(angle);

        const offsetX = radius * (cos * rightX + sin * normalizedUpX);
        const offsetY = radius * (cos * rightY + sin * normalizedUpY);
        const offsetZ = radius * (cos * rightZ + sin * normalizedUpZ);

        // 底面
        vertices.push(x1 + offsetX, y1 + offsetY, z1 + offsetZ);
        // 上面
        vertices.push(x2 + offsetX, y2 + offsetY, z2 + offsetZ);
    }

    // シリンダーのインデックスを生成
    for (let i = 0; i < segments; i++) {
        const curr = startIndex + i * 2;
        const next = startIndex + ((i + 1) % (segments + 1)) * 2;

        // 側面の四角形を2つの三角形に分割
        indices.push(curr, curr + 1, next);
        indices.push(curr + 1, next + 1, next);
    }

    return { vertices, indices };
}

// 高品質な3D分子構造GLBファイルを生成する関数
async function createSimpleGLB(sdfData: string): Promise<Buffer> {
    const { atoms, bonds } = parseSdf(sdfData);

    let allVertices: number[] = [];
    let allColors: number[] = [];  // 頂点カラーを追加
    let allIndices: number[] = [];

    // 原子を球として生成（色付き）
    atoms.forEach((atom, atomIndex) => {
        const data = atomData[atom.element] || atomData['DEFAULT'];
        const radius = data?.radius ?? 0.5;
        const { vertices, indices } = createSphere(atom.x, atom.y, atom.z, radius, 12);

        // インデックスをオフセット
        const indexOffset = allVertices.length / 3;
        allVertices.push(...vertices);
        allIndices.push(...indices.map(i => i + indexOffset));

        // この原子の色を全ての頂点に適用
        const [r, g, b] = data?.color ?? [0.8, 0.8, 0.8];
        for (let i = 0; i < vertices.length / 3; i++) {
            allColors.push(r, g, b, 1.0); // RGBA
        }
    });

    // 結合をシリンダーとして生成（原子の表面で終わらせる）
    bonds.forEach(bond => {
        const atom1 = atoms[bond.atom1 - 1];
        const atom2 = atoms[bond.atom2 - 1];

        if (atom1 && atom2) {
            // 原子のデータを取得
            const data1 = atomData[atom1.element] || atomData['DEFAULT'];
            const data2 = atomData[atom2.element] || atomData['DEFAULT'];
            const radius1 = data1?.radius ?? 0.3;
            const radius2 = data2?.radius ?? 0.3;

            // 結合ベクトルを計算
            const dx = atom2.x - atom1.x;
            const dy = atom2.y - atom1.y;
            const dz = atom2.z - atom1.z;
            const bondLength = Math.sqrt(dx * dx + dy * dy + dz * dz);

            if (bondLength > 0) {
                // 正規化されたベクトル
                const nx = dx / bondLength;
                const ny = dy / bondLength;
                const nz = dz / bondLength;

                // 結合の開始と終了点を原子の表面に調整
                const startX = atom1.x + nx * radius1;
                const startY = atom1.y + ny * radius1;
                const startZ = atom1.z + nz * radius1;

                const endX = atom2.x - nx * radius2;
                const endY = atom2.y - ny * radius2;
                const endZ = atom2.z - nz * radius2;

                // 調整後の距離が十分ある場合のみ結合を描画
                const adjustedLength = Math.sqrt(
                    (endX - startX) * (endX - startX) +
                    (endY - startY) * (endY - startY) +
                    (endZ - startZ) * (endZ - startZ)
                );

                // 閾値を0.05に設定して短い結合も表示
                if (adjustedLength > 0.05) {
                    const { vertices, indices } = createCylinder(
                        startX, startY, startZ,
                        endX, endY, endZ,
                        0.06, 8  // 少し細くして原子との違いを明確に
                    );

                    const indexOffset = allVertices.length / 3;
                    allVertices.push(...vertices);
                    allIndices.push(...indices.map(i => i + indexOffset));

                    // 結合の色（濃いグレー）を全ての頂点に適用
                    for (let i = 0; i < vertices.length / 3; i++) {
                        allColors.push(0.3, 0.3, 0.3, 1.0); // より濃いグレー
                    }
                }
            }
        }
    });

    // バウンディングボックスを計算
    let minX = Number.MAX_VALUE, minY = Number.MAX_VALUE, minZ = Number.MAX_VALUE;
    let maxX = -Number.MAX_VALUE, maxY = -Number.MAX_VALUE, maxZ = -Number.MAX_VALUE;

    for (let i = 0; i < allVertices.length; i += 3) {
        minX = Math.min(minX, allVertices[i] ?? 0);
        maxX = Math.max(maxX, allVertices[i] ?? 0);
        minY = Math.min(minY, allVertices[i + 1] ?? 0);
        maxY = Math.max(maxY, allVertices[i + 1] ?? 0);
        minZ = Math.min(minZ, allVertices[i + 2] ?? 0);
        maxZ = Math.max(maxZ, allVertices[i + 2] ?? 0);
    }

    // GLBファイルの基本構造を作成
    const json = {
        asset: { version: "2.0", generator: "Molecule Converter v2.0" },
        scene: 0,
        scenes: [{ nodes: [0] }],
        nodes: [{
            mesh: 0,
            translation: [-(minX + maxX) / 2, -(minY + maxY) / 2, -(minZ + maxZ) / 2] // 中心に移動
        }],
        meshes: [{
            primitives: [{
                attributes: {
                    POSITION: 0,
                    NORMAL: 1,
                    COLOR_0: 2  // 頂点カラーを追加
                },
                indices: 3,
                material: 0
            }]
        }],
        materials: [{
            pbrMetallicRoughness: {
                baseColorFactor: [1.0, 1.0, 1.0, 1.0], // 白にして頂点カラーを活かす
                metallicFactor: 0.0,
                roughnessFactor: 0.7
            },
            alphaMode: "OPAQUE", // 完全に不透明
            alphaCutoff: 1.0,     // アルファカットオフを最大に
            doubleSided: false,
            extras: {
                "transparency": 1.0,  // 完全に不透明
                "depthWrite": true,   // 深度バッファに書き込み
                "depthTest": true     // 深度テストを有効化
            }
        }],
        accessors: [
            {
                bufferView: 0,
                componentType: 5126, // FLOAT
                count: allVertices.length / 3,
                type: "VEC3",
                max: [maxX, maxY, maxZ],
                min: [minX, minY, minZ]
            },
            {
                bufferView: 1,
                componentType: 5126, // FLOAT
                count: allVertices.length / 3,
                type: "VEC3"
            },
            {
                bufferView: 2,
                componentType: 5126, // FLOAT
                count: allColors.length / 4,
                type: "VEC4"
            },
            {
                bufferView: 3,
                componentType: allIndices.length > 65535 ? 5125 : 5123, // UNSIGNED_INT or UNSIGNED_SHORT
                count: allIndices.length,
                type: "SCALAR"
            }
        ],
        bufferViews: [
            {
                buffer: 0,
                byteOffset: 0,
                byteLength: allVertices.length * 4,
                target: 34962  // ARRAY_BUFFER
            },
            {
                buffer: 0,
                byteOffset: allVertices.length * 4,
                byteLength: allVertices.length * 4,
                target: 34962  // ARRAY_BUFFER (normals)
            },
            {
                buffer: 0,
                byteOffset: allVertices.length * 8,
                byteLength: allColors.length * 4,
                target: 34962  // ARRAY_BUFFER (colors)
            },
            {
                buffer: 0,
                byteOffset: allVertices.length * 8 + allColors.length * 4,
                byteLength: allIndices.length * (allIndices.length > 65535 ? 4 : 2),
                target: 34963  // ELEMENT_ARRAY_BUFFER
            }
        ],
        buffers: [{
            byteLength: allVertices.length * 8 + allColors.length * 4 + allIndices.length * (allIndices.length > 65535 ? 4 : 2)
        }]
    };

    const jsonString = JSON.stringify(json);
    const jsonBuffer = Buffer.from(jsonString);

    // 法線ベクトルを計算
    const normals: number[] = new Array(allVertices.length).fill(0);
    for (let i = 0; i < allIndices.length; i += 3) {
        const idx1 = allIndices[i];
        const idx2 = allIndices[i + 1];
        const idx3 = allIndices[i + 2];

        if (idx1 === undefined || idx2 === undefined || idx3 === undefined) continue;

        const i1 = idx1 * 3;
        const i2 = idx2 * 3;
        const i3 = idx3 * 3;

        const v1x = allVertices[i1] ?? 0, v1y = allVertices[i1 + 1] ?? 0, v1z = allVertices[i1 + 2] ?? 0;
        const v2x = allVertices[i2] ?? 0, v2y = allVertices[i2 + 1] ?? 0, v2z = allVertices[i2 + 2] ?? 0;
        const v3x = allVertices[i3] ?? 0, v3y = allVertices[i3 + 1] ?? 0, v3z = allVertices[i3 + 2] ?? 0;

        const edge1x = v2x - v1x, edge1y = v2y - v1y, edge1z = v2z - v1z;
        const edge2x = v3x - v1x, edge2y = v3y - v1y, edge2z = v3z - v1z;

        const normalX = edge1y * edge2z - edge1z * edge2y;
        const normalY = edge1z * edge2x - edge1x * edge2z;
        const normalZ = edge1x * edge2y - edge1y * edge2x;

        normals[i1] = (normals[i1] ?? 0) + normalX;
        normals[i1 + 1] = (normals[i1 + 1] ?? 0) + normalY;
        normals[i1 + 2] = (normals[i1 + 2] ?? 0) + normalZ;
        normals[i2] = (normals[i2] ?? 0) + normalX;
        normals[i2 + 1] = (normals[i2 + 1] ?? 0) + normalY;
        normals[i2 + 2] = (normals[i2 + 2] ?? 0) + normalZ;
        normals[i3] = (normals[i3] ?? 0) + normalX;
        normals[i3 + 1] = (normals[i3 + 1] ?? 0) + normalY;
        normals[i3 + 2] = (normals[i3 + 2] ?? 0) + normalZ;
    }

    // 法線を正規化
    for (let i = 0; i < normals.length; i += 3) {
        const nx = normals[i] ?? 0;
        const ny = normals[i + 1] ?? 0;
        const nz = normals[i + 2] ?? 0;
        const length = Math.sqrt(nx * nx + ny * ny + nz * nz);
        if (length > 0) {
            normals[i] = nx / length;
            normals[i + 1] = ny / length;
            normals[i + 2] = nz / length;
        }
    }

    // バイナリデータを作成
    const vertexBuffer = Buffer.alloc(allVertices.length * 4);
    for (let i = 0; i < allVertices.length; i++) {
        const value = allVertices[i];
        vertexBuffer.writeFloatLE(value ?? 0, i * 4);
    }

    const normalBuffer = Buffer.alloc(normals.length * 4);
    for (let i = 0; i < normals.length; i++) {
        const value = normals[i];
        normalBuffer.writeFloatLE(value ?? 0, i * 4);
    }

    const useUint32 = allIndices.length > 65535;
    const indexBuffer = Buffer.alloc(allIndices.length * (useUint32 ? 4 : 2));
    for (let i = 0; i < allIndices.length; i++) {
        const value = allIndices[i] ?? 0;
        if (useUint32) {
            indexBuffer.writeUInt32LE(value, i * 4);
        } else {
            indexBuffer.writeUInt16LE(value, i * 2);
        }
    }

    const colorBuffer = Buffer.alloc(allColors.length * 4);
    for (let i = 0; i < allColors.length; i++) {
        let value = allColors[i] ?? 0;
        // アルファチャンネル（4番目の値）を強制的に1.0にして完全不透明に
        if ((i + 1) % 4 === 0) {
            value = 1.0;
        }
        colorBuffer.writeFloatLE(value, i * 4);
    }

    // GLBヘッダーを作成
    const binData = Buffer.concat([vertexBuffer, normalBuffer, colorBuffer, indexBuffer]);

    // JSONチャンクのパディング（4バイト境界に合わせる）
    const jsonPadding = (4 - (jsonBuffer.length % 4)) % 4;
    const paddedJsonBuffer = Buffer.concat([jsonBuffer, Buffer.alloc(jsonPadding, 0x20)]); // スペースでパディング

    // BINチャンクのパディング（4バイト境界に合わせる）
    const binPadding = (4 - (binData.length % 4)) % 4;
    const paddedBinData = Buffer.concat([binData, Buffer.alloc(binPadding, 0x00)]); // 0でパディング

    const totalLength = 12 + 8 + paddedJsonBuffer.length + 8 + paddedBinData.length;

    const header = Buffer.alloc(12);
    header.write('glTF', 0); // magic
    header.writeUInt32LE(2, 4); // version
    header.writeUInt32LE(totalLength, 8); // total length

    // JSONチャンク
    const jsonChunkHeader = Buffer.alloc(8);
    jsonChunkHeader.writeUInt32LE(paddedJsonBuffer.length, 0);
    jsonChunkHeader.write('JSON', 4);

    // BINチャンク
    const binChunkHeader = Buffer.alloc(8);
    binChunkHeader.writeUInt32LE(paddedBinData.length, 0);
    binChunkHeader.write('BIN\0', 4);

    return Buffer.concat([
        header,
        jsonChunkHeader,
        paddedJsonBuffer,
        binChunkHeader,
        paddedBinData
    ]);
}

export async function cleanupTempFiles(filePaths: string[]): Promise<void> {
    for (const filePath of filePaths) {
        try {
            await fs.unlink(filePath);
        } catch (error: any) {
            if (error.code !== 'ENOENT') console.error(error);
        }
    }
}

// ----------------- SDF Parser -----------------
function parseSdf(sdfData: string) {
    const lines = sdfData.split('\n');
    const countsLine = lines[3];
    if (!countsLine) {
        throw new Error("SDFの counts line が見つかりません");
    }
    const atomCount = parseInt(countsLine.substring(0, 3));
    const bondCount = parseInt(countsLine.substring(3, 6));

    const atoms: { x: number; y: number; z: number; element: string }[] = [];
    const bonds: { atom1: number; atom2: number; order: number }[] = [];

    for (let i = 0; i < atomCount; i++) {
        const line = lines[4 + i];
        if (!line) continue;
        const x = parseFloat(line.substring(0, 10));
        const y = parseFloat(line.substring(10, 20));
        const z = parseFloat(line.substring(20, 30));
        const element = line.substring(31, 34).trim();
        atoms.push({ x, y, z, element });
    }

    for (let i = 0; i < bondCount; i++) {
        const line = lines[4 + atomCount + i];
        if (!line) continue;
        const atom1 = parseInt(line.substring(0, 3));
        const atom2 = parseInt(line.substring(3, 6));
        const order = parseInt(line.substring(6, 9));
        bonds.push({ atom1, atom2, order });
    }

    return { atoms, bonds };
}

// ----------------- Element Data (CPK Colors) -----------------
const atomData: { [element: string]: { radius: number; color: [number, number, number] } } = {
    'H': { radius: 0.2, color: [1.0, 1.0, 1.0] }, // White (フロントエンド: Colors.white) - より小さく
    'C': { radius: 0.4, color: [0.0, 0.0, 0.0] }, // Black (フロントエンド: Colors.black)
    'N': { radius: 0.35, color: [0.0, 0.0, 1.0] }, // Blue (フロントエンド: Colors.blue)
    'O': { radius: 0.35, color: [1.0, 0.0, 0.0] }, // Red (フロントエンド: Colors.red)
    'P': { radius: 0.5, color: [1.0, 0.65, 0.0] }, // Orange (フロントエンド: Colors.orange)
    'S': { radius: 0.45, color: [1.0, 1.0, 0.0] }, // Yellow (フロントエンド: Colors.yellow)
    'F': { radius: 0.3, color: [0.0, 1.0, 0.0] }, // Green - フロントには表示されていないが一般的な色
    'Cl': { radius: 0.5, color: [0.0, 1.0, 0.0] }, // Green
    'Br': { radius: 0.55, color: [0.65, 0.16, 0.16] }, // Dark Red/Brown
    'I': { radius: 0.6, color: [0.58, 0.0, 0.58] }, // Purple
    'B': { radius: 0.4, color: [1.0, 0.71, 0.71] }, // Pink
    'Si': { radius: 0.5, color: [0.78, 0.78, 0.86] }, // Light Grey
    'DEFAULT': { radius: 0.3, color: [0.8, 0.8, 0.8] }, // Light Gray
};

// ----------------- Main API -----------------
export async function convertSdfToGlb(sdfData: string): Promise<Buffer> {
    try {
        // 簡単なGLBファイルを直接生成（3D分子構造として）
        const glbData = await createSimpleGLB(sdfData);
        console.log('GLB conversion successful using custom generator');
        return glbData;
    } catch (error) {
        console.error('Conversion failed:', error);
        throw new Error('SDF->GLB conversion failed.');
    }
}
