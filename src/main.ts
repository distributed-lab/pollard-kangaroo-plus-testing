import { KangarooEd25519 } from "./kangaroo_ed25519";
import { ed25519 } from "@noble/curves/ed25519";
import { KangarooSecp256k1 } from "./kangaroo_secp256k1";
import { secp256k1 } from "@noble/curves/secp256k1";

function uint8ArrayToBigInt(uint8Array: Uint8Array): bigint {
    let result = BigInt(0);
    for (let i = 0; i < uint8Array.length; i++) {
        result = (result << BigInt(8)) | BigInt(uint8Array[i]);
    }

    return result;
}

function padWithZerosEnd(input: string, length: number): string {
    if (input.length >= length) {
        return input;
    }
    return input+'0'.repeat(length - input.length);
}

function dlpEd25519() {
    const kangaroo = new KangarooEd25519(400, 63572n, 32);

    let privateKey = 313249263n
    let publicKey = uint8ArrayToBigInt(ed25519.getPublicKey(padWithZerosEnd(privateKey.toString(16), 64)))

    const startPreprocTime = performance.now();
    kangaroo.generateTable();
    const endPreprocTime = performance.now();

    const elapsedPreprocTime = endPreprocTime - startPreprocTime;
    console.log(`Preprocessing time: ${elapsedPreprocTime/1000} seconds`);

    const startMainTime = performance.now();
    const log = kangaroo.solveDLP(publicKey);
    const endMainTime = performance.now();

    const elapsedMainTime = endMainTime - startMainTime;
    console.log(`Main time: ${elapsedMainTime/1000} seconds`);

    console.log("Found private key: ", log)
    console.log("Do private keys match: ", log == privateKey)
}

function dlpSecp256k1() {
    const kangaroo = new KangarooSecp256k1(400, 63572n, 32);

    let privateKey = 313249263n
    let publicKey = uint8ArrayToBigInt(secp256k1.getPublicKey(privateKey))

    console.log(publicKey.toString(16))

    const startPreprocTime = performance.now();
    kangaroo.generateTable();
    const endPreprocTime = performance.now();

    const elapsedPreprocTime = endPreprocTime - startPreprocTime;
    console.log(`Preprocessing time: ${elapsedPreprocTime/1000} seconds`);

    const startMainTime = performance.now();
    const log = kangaroo.solveDLP(publicKey);
    const endMainTime = performance.now();

    const elapsedMainTime = endMainTime - startMainTime;
    console.log(`Main time: ${elapsedMainTime/1000} seconds`);

    console.log("Found private key: ", log)
    console.log("Do private keys match: ", log == privateKey)
}

// dlpEd25519()
dlpSecp256k1()

// const startTime = performance.now();
// kangaroo.generateTable(1).then(_ => {
//     const endTime = performance.now();
//     const elapsedTime = endTime - startTime;
    
//     console.log(`Execution time: ${elapsedTime/1000} seconds`);
// })
