import { secp256k1 } from "@noble/curves/secp256k1";
import { Utils, WorkerData } from "../utils";

export class KangarooSecp256k1 {
    n: number;
    w: bigint;
    l: bigint;
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
        this.r = 64n;
        
        this.s = new Array<bigint>();
        this.slog = new Array<bigint>();

        this.table = new Map<bigint, bigint>

        this.initS();
    }

    private initS() {
        for (let i = 0; i < this.r; i++) {
            const sValue = Utils.generateRandomIntegerInRange(
                Number(Utils.generateRandomInteger(this.secretSize - 2) / this.w)
            ) 
            
            // TODO: there might be a case when sValue is 0
            this.slog[i] = sValue
            this.s[i] = Utils.uint8ArrayToBigInt(secp256k1.getPublicKey(sValue, true))
        }
    }

    generateTable() {
        let tableDone = 0;

        while (tableDone < this.n) {
            let wlog = Utils.generateRandomInteger(this.secretSize)
            let w = Utils.uint8ArrayToBigInt(secp256k1.getPublicKey(wlog))

            for (let loop = 0; loop < 8n*this.w; loop++) {
                if (Utils.isDistinguished(w, this.w)) {
                    const tableEntry = this.table.get(w);

                    if (tableEntry == undefined) {
                        this.table.set(w, wlog)
                        tableDone++

                        console.log("tabledone: " + tableDone + " / " + this.n)
                    } 

                    break
                }

                const h = Utils.hash(w, this.r)                
                wlog = wlog + this.slog[h]                
                w = Utils.addPointsSecp256k1(w, this.s[h])
            }
        }
    }

    async solveDLP(pubKey: bigint, numberOfThreads: number = navigator.hardwareConcurrency || 1): Promise<bigint> {
        const workerData = new WorkerData(this.secretSize, pubKey, this.w, this.r, this.slog, this.s, this.table);

        let workers: Worker[] = []
        for (let i = 0; i < numberOfThreads; i++) {
            const worker = new Worker(new URL('./worker.ts', import.meta.url));
            workers.push(worker)
            worker.postMessage(workerData);
        }

        let result = await Utils.waitForAnyWorker(workers)
        Utils.terminateWorkers(workers)
        
        return result
    }
}