import { create_kangaroo } from "./pkg/pollard_kangaroo";

import fs from "fs";

async function main() {
    const dl_bits = 32;
    const w = 2048n;
    const n = 4000n;
    const r = 128n;

    const file = `../table-server/output_${w}_${n}_${dl_bits}_${r}.json`;

    const content = fs.readFileSync(file);
    const data = JSON.parse(content.toString());

    const c = create_kangaroo(data, n, w, r, dl_bits);

    let time: number = 0;
    let highestTime: number = 0;
    let lowestTime: number = 9999999999999999999;
    let secretsNum = 30;

    for (let i = 0; i < secretsNum; i++) {
        const startMainTime = performance.now();

        const u8 = fromHexString("9e4decf80cc272c511b60395a50fef5c73116f50f21d6304d729fb83fe027271");
        console.log(u8);

        const sk = c.solve_dlp(u8);
        console.log(sk);

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
        console.log("Processed " + i + " / " + secretsNum + " secrets")
        console.log("Mean time: " + time / (i+1) + " seconds")
        console.log("----\n")
    }
}

const fromHexString = (hexString: string) => Uint8Array.from(Buffer.from(hexString, 'hex'));

main().catch(console.error);