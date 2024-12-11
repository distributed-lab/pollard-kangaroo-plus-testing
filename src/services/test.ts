import { ed25519 } from "@noble/curves/ed25519";
import { secp256k1 } from "@noble/curves/secp256k1";
import { KangarooSecp256k1 } from "./secp256k1/algorithm";
import { Utils } from "./utils";

import { KangarooEd25519 } from "./ed25519/algorithm";
import { hexToBytes } from "@noble/curves/abstract/utils";
import { KangarooRistretto } from "./ristretto/algorithm";

function uint8ArrayToBigInt(uint8Array: Uint8Array): bigint {
    let result = BigInt(0);
    for (let i = 0; i < uint8Array.length; i++) {
        result = (result << BigInt(8)) | BigInt(uint8Array[i]);
    }

    return result;
}

function isDistinguished(pubKey: bigint): boolean {
    return !(pubKey & (2048n - 1n))
}

export async function dlpSecp256k1() {
    const kangaroo = new KangarooSecp256k1(100, 4096n/2n, 32);
    
    const startPreprocTime = performance.now();
    kangaroo.generateTable();
    const endPreprocTime = performance.now();

    const elapsedPreprocTime = endPreprocTime - startPreprocTime;
    console.log(`Preprocessing time: ${elapsedPreprocTime/1000} seconds`);

    let time: number = 0
    let highestTime: number = 0
    let lowestTime: number = 9999999999999999999
    let secretsNum = 30
    for (let i = 0; i < secretsNum; i++) {
        let privateKey = Utils.generateRandomInteger(32)
        let publicKey = uint8ArrayToBigInt(secp256k1.getPublicKey(privateKey))
        console.log("Looking for " + privateKey + ". Target - " + publicKey)
    
    
        const startMainTime = performance.now();
        let log = await kangaroo.solveDLP(publicKey)
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
        console.log("Processed " + i + " / " + secretsNum + " secrets")
        console.log("Mean time: " + time / (i+1) + " seconds")
        console.log("----\n")
    }

    console.log("Highest time: " + highestTime/1000 + " seconds")
    console.log("Lowest time: " + lowestTime/1000 + " seconds")
}

export async function dlpRistretto(n:number, w: bigint, r: bigint, secretSize: number) {
    const kangaroo = new KangarooRistretto(n, w, r, secretSize);

    if (!await kangaroo.readJsonFromServer()) {
        console.log("could not read JSON table from the server")
        return
    }

    let time: number = 0
    let highestTime: number = 0
    let lowestTime: number = 9999999999999999999
    let secretsNum = 200
    for (let i = 0; i < secretsNum; i++) {

        let privateKey = Utils.generateRandomInteger(secretSize)
        console.log(privateKey)
        let publicKey = kangaroo.mulBasePoint(privateKey)
        console.log("Looking for " + privateKey + ". Target - " + publicKey)
    
        const startMainTime = performance.now();
        const log = await kangaroo.solveDLPTest(publicKey)
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
        console.log("Processed " + i + " / " + secretsNum + " secrets")
        console.log("Mean time: " + time / (i+1) + " seconds")
        console.log("----\n")

        kangaroo.writeLogsToServer( "Log: " + log.toString(16) + "\n" +
            "Highest time: " + highestTime/1000 + " seconds\n" +
            `Main time: ${elapsedMainTime/1000} seconds\n` +
            "Mean time: " + time / (i+1) + " seconds\n")
    }

    console.log("Highest time: " + highestTime/1000 + " seconds")
    console.log("Lowest time: " + lowestTime/1000 + " seconds")

    kangaroo.writeLogsToServer("Highest time: " + highestTime/1000 + " seconds\n"
        + "Lowest time: " + lowestTime/1000 + " seconds\n")
}

const testData = [
    {n: 17000, w: 4n, r: 64n, secret_size: 16},
    // {n: 1090, w: 64n, r: 128n, secret_size: 16},
    // {n: 500, w: 128n, r: 128n, secret_size: 16},
    // {n: 80, w: 256n, r: 128n, secret_size: 16},
]

async function launchTests() {
    for (const data of testData) {
        await dlpRistretto(data.n, data.w, data.r, data.secret_size);
    }
}

launchTests().then()