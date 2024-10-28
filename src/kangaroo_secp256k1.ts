import { secp256k1 } from "@noble/curves/secp256k1";
import * as WorkerPool from 'workerpool';
import * as Path from 'path';

const kangarooWorkerPath = './kangaroo_worker.ts'

export class KangarooSecp256k1 {
    n: number;
    w: bigint;
    l: bigint;
    g: bigint;
    r: bigint;
    secretSize: number;

    s: bigint[];
    slog: bigint[];

    table: Map<bigint, bigint>

    constructor(n: number, w: bigint, secretSize: number) {
        this.n = n; 
        this.w = w; 
        this.secretSize = secretSize; 
        this.l = BigInt(2**secretSize);
        this.r = 128n;
        
        const g = secp256k1.CURVE.p / this.l;
        this.g = (g * g) % secp256k1.CURVE.p;

        this.s = new Array<bigint>();
        this.slog = new Array<bigint>();

        this.table = new Map<bigint, bigint>

        this.initS();
    }

    private async initPool(numberOfThreads: number) {
        const options = { minWorkers: numberOfThreads, maxWorkers: numberOfThreads }
        const pool: WorkerPool.Pool = WorkerPool.pool(Path.join(__dirname, kangarooWorkerPath), options);
        const proxy = await pool.proxy();

        return {pool, proxy}
    }

    private uint8ArrayToBigInt(uint8Array: Uint8Array): bigint {
        let result = BigInt(0);
        for (let i = 0; i < uint8Array.length; i++) {
            result = (result << BigInt(8)) | BigInt(uint8Array[i]);
        }

        return result;
    }
    
    private bigintToUint8Array(value: BigInt): Uint8Array {
        // Convert BigInt to a hexadecimal string
        const hexString = value.toString(16);
        
        // Pad with zeros if necessary to ensure an even length
        const paddedHexString = hexString.length % 2 === 0 ? hexString : '0' + hexString;
        
        // Create a byte array from the hexadecimal string
        const byteArray = new Uint8Array(32);
        for (let i = 0; i < paddedHexString.length; i += 2) {
            byteArray[i / 2] = parseInt(paddedHexString.substr(i, 2), 16);
        }
    
        return byteArray;
    }

    private isDistinguished(pubKey: bigint): boolean {
        return !(pubKey & (this.w - 1n))
    }

    private hash(pubKey: bigint): number {
        return Number(pubKey & (this.r - 1n))
    }

    private generateRandomInteger(bits: number): bigint {
        const max = (1n << BigInt(bits)) - 1n;
        const randomValue = BigInt(Math.floor(Math.random() * (Number(max) + 1))); 
    
        return randomValue;
    }

    private generateRandomIntegerInRange(n: number): bigint {
        const randomValue = BigInt(Math.floor(Math.random() * n));
    
        return randomValue;
    }

    private initS() {
        for (let i = 0; i < this.r; i++) {
            const sValue = this.generateRandomIntegerInRange(
                Number(this.generateRandomInteger(this.secretSize - 2) / this.w)
            )
            
            // TODO: there might be a case when sValue is 0. We need to handle this
            this.slog[i] = sValue
            this.s[i] = this.uint8ArrayToBigInt(secp256k1.getPublicKey(sValue, true))
        }
    }
    

    // async generateTable(numberOfThreads: number = navigator.hardwareConcurrency || 1) {
    //     console.log(numberOfThreads)

    //     let {pool, proxy} = await this.initPool(numberOfThreads);
    //     const sharedBuffer = new SharedArrayBuffer(4); // 4 bytes for one Int32
    //     const sharedArray = new Int32Array(sharedBuffer);   

    //     const promises = [];
    //     for (let i = 0; i < numberOfThreads; i++) {
    //         promises.push(proxy.generateTableThread(i, sharedArray))
    //     }
    //     Promise.all(promises).then(_ => console.log("all promises are done"))

//     // await lastPromise;
    //     console.log(sharedArray[0])
        
    //     // proxy.bcryptHashh(3000).then(_ => console.log("done 0"))
    //     // proxy.bcryptHashh(0).then(_ => console.log("done 1"))
    //     // proxy.bcryptHashh(100).then(_ => console.log("done 3"))
    //     // proxy.bcryptHashh(2000).then(_ => console.log("done 4"))

    //     pool.terminate()
    // }

    private padWithZerosEnd(input: string, length: number): string {
        if (input.length >= length) {
            return input;
        }
        return input+'0'.repeat(length - input.length);
    }

    private padWithZerosBeginning(input: string, length: number): string {
        if (input.length >= length) {
            return input;
        }
        return '0'.repeat(length - input.length) + input;
    }

    private addPoints(point1: bigint, point2: bigint): bigint {
        const paddedPoint1 = this.padWithZerosBeginning(point1.toString(16), 66);
        const point1Projective = secp256k1.ProjectivePoint.fromHex(paddedPoint1)

        const paddedPoint2 = this.padWithZerosBeginning(point2.toString(16), 66);
        const point2Projective = secp256k1.ProjectivePoint.fromHex(paddedPoint2)

        return BigInt("0x" + point1Projective.add(point2Projective).toHex())
    }

    generateTable() {
        let tableDone = 0;

        while (tableDone < this.n) {
            let wlog = this.generateRandomInteger(this.secretSize)
            let w = this.uint8ArrayToBigInt(secp256k1.getPublicKey(wlog))

            for (let loop = 0; loop < 8n*this.w; loop++) {
                if (this.isDistinguished(w)) {
                    const tableEntry = this.table.get(w);

                    if (tableEntry == undefined) {
                        this.table.set(w, wlog)
                        tableDone++

                        console.log("tabledone: " + tableDone + " / " + this.n)
                    } 

                    break
                }

                const h = this.hash(w)                
                wlog = wlog + this.slog[h]                
                w = this.addPoints(w, this.s[h])
            }
        }
    }

    solveDLP(pubKey: bigint): bigint {
        while(true) {
            let wdist = this.generateRandomInteger(this.secretSize)
            let w = this.addPoints(pubKey, this.uint8ArrayToBigInt(secp256k1.getPublicKey(wdist)))

            for (let loop = 0; loop < 8n * this.w; loop++) {
                if (this.isDistinguished(w)) {
                    const tableEntry = this.table.get(w)

                    if (tableEntry != undefined) {
                        wdist = tableEntry - wdist
                    }

                    break
                } 

                const h = this.hash(w)                
                wdist = wdist + this.slog[h]                
                w = this.addPoints(w, this.s[h])
            }

            if (this.uint8ArrayToBigInt(secp256k1.getPublicKey(wdist)) == pubKey) {
                return wdist
            }
        }
    }
}