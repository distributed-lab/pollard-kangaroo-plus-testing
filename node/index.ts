import { create_kangaroo } from "./pkg/pollard_kangaroo";
import { RistrettoPoint } from "@noble/curves/ed25519";

import fs from "fs";

function generateRandomInteger(bits: number): bigint {
    const max = (1n << BigInt(bits)) - 1n;
    return BigInt(Math.floor(Math.random() * (Number(max) + 1)));
}

function mulBasePoint(scalar: bigint): bigint {
    return BigInt('0x' + RistrettoPoint.BASE.multiply(scalar).toHex())
}

const fromHexString = (hexString: string) => Uint8Array.from(Buffer.from(hexString.padStart(64, "0"), "hex"));

export async function dlpRistretto(n: bigint, w: bigint, r: bigint, dl_bits: number) {
    const file = `../table-server/output_${w}_${n}_${dl_bits}_${r}.json`;
    const content = fs.readFileSync(file);
    const data = JSON.parse(content.toString());

    const kangaroo = create_kangaroo(data, n, w, r, dl_bits);

    let time: number = 0
    let highestTime: number = 0
    let lowestTime: number = 9999999999999999999
    let secretsNum = 200

    for (let i = 0; i < secretsNum; i++) {
        let privateKey = generateRandomInteger(dl_bits)
        console.log(privateKey)
        let publicKey = mulBasePoint(privateKey);
        console.log("Looking for " + privateKey + ". Target - " + publicKey)

        const pubKeyBytes = fromHexString(publicKey.toString(16));

        const startMainTime = performance.now();
        const log = kangaroo.solve_dlp(pubKeyBytes);
        const endMainTime = performance.now();

        const elapsedMainTime = endMainTime - startMainTime;

        time += elapsedMainTime / 1000

        if (elapsedMainTime > highestTime) {
            highestTime = elapsedMainTime
        }

        if (elapsedMainTime < lowestTime) {
            lowestTime = elapsedMainTime
        }

        console.log(`Main time: ${elapsedMainTime/1000} seconds`);
        console.log("Found private key: ", log)
        console.log("Do private keys match: ", log == privateKey)
        console.log("Processed " + (i + 1) + " / " + secretsNum + " secrets")
        console.log("Mean time: " + time / (i+1) + " seconds")
        console.log("----\n")
    }

    console.log("Highest time: " + highestTime/1000 + " seconds")
    console.log("Lowest time: " + lowestTime/1000 + " seconds")
    console.log("Mean time: " + time / secretsNum + " seconds");
}

async function main() {
    const dl_bits = 32;
    const w = 2048n;
    const n = 4000n;
    const r = 128n;

    // const dl_bits = 48;
    // const w = 65536n;
    // const n = 40000n;
    // const r = 128n;

    await dlpRistretto(n, w, r, dl_bits);
}

main().catch(console.error);
