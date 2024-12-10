import { ed25519, RistrettoPoint } from "@noble/curves/ed25519";
import { secp256k1 } from "@noble/curves/secp256k1";
import { KangarooSecp256k1 } from "./secp256k1/algorithm";
import { Utils } from "./utils";

import { KangarooEd25519 } from "./ed25519/algorithm";
import { babyStepGiantStepRistretto } from "../babyStepGiantStep";

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

export async function dlpEd25519(n:number, w: bigint, r: bigint, secretSize: number) {
    const kangaroo = new KangarooEd25519(n, w, r, secretSize);
    
    let privateKey = BigInt("0x3c97d734")//Utils.generateRandomInteger(secretSize)
    let publicKey = BigInt("0xabbfc9ba9888735ae30f830196c16e51fdae386ec7b49bc76087bdd7dbe2cfce")

    //3c97d734
    //abbfc9ba9888735ae30f830196c16e51fdae386ec7b49bc76087bdd7dbe2cfce


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

export const testBabyStepGiantStep = async (n: number, secretSize: number) => {
    let time: number = 0
    let highestTime: number = 0
    let lowestTime: number = 9999999999999999999
    let secretsNum = 200


    const base = RistrettoPoint.BASE;

    for (let i = 0; i < secretsNum; i++) {
        let privateKey = Utils.generateRandomInteger(secretSize)
        let publicKey = base.multiply(privateKey)
        console.log("Looking for " + privateKey + ". Target - " + publicKey)
    
        const startMainTime = performance.now();

        const found = babyStepGiantStepRistretto(base, publicKey, BigInt(n));
        console.log(found?.toString());
        

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
        console.log("Found private key: ", found)
        console.log("Do private keys match: ", found === privateKey)
        console.log("Processed " + i + " / " + secretsNum + " secrets")
        console.log("Mean time: " + time / (i+1) + " seconds")
        console.log("----\n")

        // kangaroo.writeLogsToServer( "Log: " + log.toString(16) + "\n" +
        //     "Highest time: " + highestTime/1000 + " seconds\n" +
        //     `Main time: ${elapsedMainTime/1000} seconds\n` +
        //     "Mean time: " + time / (i+1) + " seconds\n")
    }

    console.log("Highest time: " + highestTime/1000 + " seconds")
    console.log("Lowest time: " + lowestTime/1000 + " seconds")
}

const testData = [
    {n: 4000, w: 2048n, r: 64n, secret_size: 32},
]

export async function launchTests() {
    for (const data of testData) {
        await dlpEd25519(data.n, data.w, data.r, data.secret_size);
        await testBabyStepGiantStep(2 ** data.secret_size, data.secret_size);
    }
}

// launchTests().then()
