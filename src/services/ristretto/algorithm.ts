import { RistrettoPoint } from "@noble/curves/ed25519";
import { Utils, WorkerData } from "../utils";
import { TableMap } from "./tablemap";

export class KangarooRistretto {
    n: number;
    w: bigint;
    l: bigint;
    g: bigint;
    r: bigint;
    secretSize: number;

    public table: TableMap

    constructor(n: number, w: bigint, r: bigint, secretSize: number) {
        this.n = n; 
        this.w = w; 
        this.secretSize = secretSize; 
        this.l = BigInt(2**secretSize);
        this.r = r;
        
        this.table = new TableMap()
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

    public mulBasePoint(scalar: bigint): bigint {
        return BigInt('0x' + RistrettoPoint.BASE.multiply(scalar).toHex())
    }

    // async solveDLP(pubKey: bigint, numberOfThreads: number = navigator.hardwareConcurrency || 1): Promise<bigint> {
    //     const pubKeyPoint = RistrettoPoint.fromHex(pubKey.toString(16).padStart(64, "0"))
    //     const workerData = new WorkerData(this.secretSize, pubKeyPoint, this.w, this.r, this.table.slog, this.table.s, this.table.table);

    //     let workers: Worker[] = []
    //     for (let i = 0; i < numberOfThreads; i++) {
    //         const worker = new Worker(new URL('./worker.ts', import.meta.url));
    //         workers.push(worker)
    //         worker.postMessage(workerData);
    //     }

    //     let result = await Utils.waitForAnyWorker(workers);
    //     Utils.terminateWorkers(workers)

    //     return result
    // }

    async solveDLPTest(pubKey: bigint): Promise<bigint> {
        // TODO: change solveDLPTest argument to ExtendedPoint
        const pubKeyPoint = RistrettoPoint.fromHex(pubKey.toString(16).padStart(64, "0"))

        while(true) {
            let wdist = Utils.generateRandomInteger(this.secretSize-8)
            console.log(wdist)

            let w = pubKeyPoint.add(RistrettoPoint.BASE.multiply(wdist))
            let wBig = BigInt("0x"+w.toHex())

            for (let loop = 0; loop < 8n * this.w; loop++) {
                if (Utils.isDistinguished(wBig, this.w)) {
                    const tableEntry = this.table.get(wBig)
    
                    if (tableEntry != undefined) {
                        wdist = tableEntry - wdist

                        if (BigInt('0x'+RistrettoPoint.BASE.multiply(wdist).toHex()) == pubKey) {
                            postMessage(wdist)
                            return wdist
                        }
                    }
    
                    break
                } 
    
                const h = Utils.hash(wBig, this.r)         
                wdist = wdist + this.table.slog[h]    
                
                w = w.add(RistrettoPoint.fromHex(this.table.s[h].toString(16)))
                wBig = BigInt('0x'+w.toString())
            }
        }
    }

    async writeJsonToServer() {
        const tableJSON = this.table.writeJson(this.w, this.n, this.secretSize, this.r)

        await fetch('http://localhost:3001/upload', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json', 
            },
            body: tableJSON,
        })
    }

    async readJsonFromServer(): Promise<boolean> {
        const response = await fetch(`http://localhost:3001/table?file_name=output_${this.w.toString()}_${this.n}_${this.secretSize}_${this.r}.json`)
        
        if (!response.ok) {
            return false
        }
        
        this.table.readJson(JSON.stringify(await response.json()))
        return true
    }

    async writeLogsToServer(text: string) {
        await fetch('http://localhost:3001/log', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json', 
            },
            body: JSON.stringify({
                filename: `log_${this.w.toString()}_${this.n}_${this.secretSize}.txt`,
                text: text,
            }),
        })
    }
}
