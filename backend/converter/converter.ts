// converter.ts
import { promises as fs } from 'fs';
import { exec } from 'child_process';
import util from 'util';
import path from 'path';
import os from 'os';

const execPromise = util.promisify(exec);

export async function cleanupTempFiles(filePaths: string[]): Promise<void> {
    for (const filePath of filePaths) {
        try { await fs.unlink(filePath); }
        catch (error: any) { if (error.code !== 'ENOENT') console.error(error); }
    }
}

// ----------------- SDF Parser -----------------
function parseSdf(sdfData: string) {
    const lines = sdfData.split('\n');

    // 4行目が counts line
    const countsLine = lines[3];

    if (!countsLine) {
        throw new Error("SDFの counts line が見つかりません");
    }
    const atomCount = parseInt(countsLine.substr(0, 3));
    const bondCount = parseInt(countsLine.substr(3, 3));

    const atoms: { x: number; y: number; z: number; element: string }[] = [];
    const bonds: { a: number; b: number; order: number }[] = [];

    // Atoms
    for (let i = 0; i < atomCount; i++) {
        const line = lines[4 + i];
        if (!line) {
            throw new Error("SDFに M END 行が見つかりません");
        }
        const x = parseFloat(line.substr(0, 10));
        const y = parseFloat(line.substr(10, 10));
        const z = parseFloat(line.substr(20, 10));
        const element = line.substr(31, 3).trim();
        atoms.push({ x, y, z, element });
    }

    // Bonds
    for (let i = 0; i < bondCount; i++) {
        const line = lines[4 + atomCount + i];
        if (!line) {
            throw new Error("SDFに M END 行が見つかりません");
        }
        const a = parseInt(line.substr(0, 3));
        const b = parseInt(line.substr(3, 3));
        const order = parseInt(line.substr(6, 3));
        bonds.push({ a, b, order });
    }

    return { atoms, bonds };
}

// ----------------- OBJ生成 -----------------
function generateSphereObj(cx: number, cy: number, cz: number, r = 0.2, segments = 8) {
    const vertices: string[] = [];
    const faces: string[] = [];
    for (let i = 0; i <= segments; i++) {
        const lat = Math.PI * i / segments;
        const sinLat = Math.sin(lat);
        const cosLat = Math.cos(lat);
        for (let j = 0; j <= segments; j++) {
            const lon = 2 * Math.PI * j / segments;
            const sinLon = Math.sin(lon);
            const cosLon = Math.cos(lon);
            const x = cx + r * sinLat * cosLon;
            const y = cy + r * sinLat * sinLon;
            const z = cz + r * cosLat;
            vertices.push(`v ${x} ${y} ${z}`);
        }
    }
    for (let i = 0; i < segments; i++) {
        for (let j = 0; j < segments; j++) {
            const a = i * (segments + 1) + j + 1;
            const b = a + segments + 1;
            faces.push(`f ${a} ${b} ${b + 1} ${a + 1}`);
        }
    }
    return { vertices, faces };
}

function generateCylinderBetweenAtoms(a: { x: number, y: number, z: number }, b: { x: number, y: number, z: number }, r = 0.05, segments = 6) {
    const vertices: string[] = [];
    const faces: string[] = [];
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const dz = b.z - a.z;
    const length = Math.sqrt(dx * dx + dy * dy + dz * dz);
    if (length === 0) return { vertices, faces };

    // Z軸円柱
    for (let i = 0; i <= segments; i++) {
        const angle = 2 * Math.PI * i / segments;
        const cx = r * Math.cos(angle);
        const cy = r * Math.sin(angle);
        vertices.push(`v ${cx} ${cy} 0`);
        vertices.push(`v ${cx} ${cy} ${length}`);
    }
    for (let i = 0; i < segments; i++) {
        const aIdx = i * 2 + 1;
        const bIdx = i * 2 + 2;
        const cIdx = aIdx + 2;
        const dIdx = bIdx + 2;
        faces.push(`f ${aIdx} ${bIdx} ${dIdx} ${cIdx}`);
    }

    // 回転・平行移動
    const ux = dx / length, uy = dy / length, uz = dz / length;
    const vx = -uy, vy = ux, vz = 0;
    const wx = -uz * ux, wy = -uz * uy, wz = 1;
    for (let i = 0; i < vertices.length; i++) {
        const line = vertices[i];
        if (!line) continue;
        const parts = line.substr(2).trim().split(/\s+/).map(Number);
        if (parts.length !== 3 || parts.some((n) => isNaN(n))) continue;

        const [vx0, vy0, vz0] = parts as [number, number, number];
        const xNew = vx0 * ux + vy0 * vx + vz0 * wx + a.x;
        const yNew = vx0 * uy + vy0 * vy + vz0 * wy + a.y;
        const zNew = vx0 * uz + vy0 * vz + vz0 * wz + a.z;
        vertices[i] = `v ${xNew} ${yNew} ${zNew}`;
    }

    return { vertices, faces };
}

async function convertSdfToObj(sdfData: string): Promise<string> {
    const { atoms, bonds } = parseSdf(sdfData);

    let vertices: string[] = [];
    let faces: string[] = [];

    // 原子を球に
    for (const atom of atoms) {
        const { vertices: v, faces: f } = generateSphereObj(atom.x, atom.y, atom.z, 0.2, 8);
        const offset = vertices.length;
        vertices = vertices.concat(v);
        faces = faces.concat(f.map(face => face.replace(/\d+/g, (num) => (parseInt(num) + offset).toString())));
    }

    // 結合を円柱に
    for (const bond of bonds) {
        const a = atoms[bond.a - 1];
        const b = atoms[bond.b - 1];
        if (!a || !b) continue;
        const { vertices: v, faces: f } = generateCylinderBetweenAtoms(a, b, 0.05, 6);
        const offset = vertices.length;
        vertices = vertices.concat(v);
        faces = faces.concat(f.map(face => face.replace(/\d+/g, (num) => (parseInt(num) + offset).toString())));
    }

    const tempId = `mol_${Date.now()}`;
    const objPath = path.join(os.tmpdir(), `${tempId}.obj`);
    await fs.writeFile(objPath, [...vertices, ...faces].join('\n'));
    return objPath;
}

// ----------------- OBJ→GLB -----------------
async function convertObjToGlb(objPath: string): Promise<string> {
    const glbPath = objPath.replace('.obj', '.glb');
    try {
        const { stderr } = await execPromise(`npx obj2gltf -i ${objPath} -o ${glbPath}`);
        if (stderr) console.warn('obj2gltf stderr:', stderr);
        await fs.access(glbPath);
        return glbPath;
    } catch (error) {
        console.error(error);
        throw new Error('OBJ->GLB failed.');
    }
}

// ----------------- Main API -----------------
export async function convertSdfToGlb(sdfData: string): Promise<string> {
    let objPath: string | undefined;
    try {
        objPath = await convertSdfToObj(sdfData);
        const glbPath = await convertObjToGlb(objPath);
        return glbPath;
    } finally {
        if (objPath) await cleanupTempFiles([objPath]);
    }
}
