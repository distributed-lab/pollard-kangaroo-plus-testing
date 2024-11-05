import { ed25519 } from "@noble/curves/ed25519";
import { secp256k1 } from "@noble/curves/secp256k1";
import { KangarooSecp256k1 } from "./secp256k1/algorithm";
import { Utils } from "./utils";

import { KangarooEd25519 } from "./ed25519/algorithm";

function uint8ArrayToBigInt(uint8Array: Uint8Array): bigint {
    let result = BigInt(0);
    for (let i = 0; i < uint8Array.length; i++) {
        result = (result << BigInt(8)) | BigInt(uint8Array[i]);
    }

    return result;
}

export async function dlpSecp256k1(secretSize: number) {
    const kangaroo = new KangarooSecp256k1(100, 2048n, secretSize);
    
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
        let privateKey = Utils.generateRandomInteger(secretSize)
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

export async function dlpEd25519(secretSize: number) {
    const kangaroo = new KangarooEd25519(500, 2048n, secretSize);
    
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
        let privateKey = Utils.generateRandomInteger(secretSize)
        let publicKey = kangaroo.mulBasePoint(privateKey)
        console.log("Looking for " + privateKey + ". Target - " + publicKey)
    
        const startMainTime = performance.now();
        const log = await kangaroo.solveDLP(publicKey)
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

dlpEd25519(48).then()
