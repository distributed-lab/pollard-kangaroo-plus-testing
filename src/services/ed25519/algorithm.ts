import { ed25519 } from "@noble/curves/ed25519";
import { Utils, WorkerData } from "../utils";
import { TableMap } from "../tablemap";

export class KangarooEd25519 {
    n: number;
    w: bigint;
    l: bigint;
    g: bigint;
    r: bigint;
    secretSize: number;

    // s: bigint[];
    table: TableMap

    constructor(n: number, w: bigint, secretSize: number) {
        this.n = n; 
        this.w = w; 
        this.secretSize = secretSize; 
        this.l = BigInt(2**secretSize);
        this.r = 128n;
        
        this.table = new TableMap()

        this.initS();
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
            
            // TODO: there might be a case when sValue is 0
            this.table.slog[i] = sValue
            this.table.s[i] = this.mulBasePoint(sValue)
        }
    }

    private addPoints(point1: bigint, point2: bigint): bigint {
        const paddedPoint1 = point1.toString(16).padStart(64, '0');
        const point1Extended = ed25519.ExtendedPoint.fromHex(paddedPoint1)

        const paddedPoint2 = point2.toString(16).padStart(64, '0');
        const point2Extended = ed25519.ExtendedPoint.fromHex(paddedPoint2)

        return BigInt("0x" + point1Extended.add(point2Extended).toHex())
    }

    public mulBasePoint(scalar: bigint): bigint {
        return BigInt('0x' + ed25519.ExtendedPoint.BASE.multiply(scalar).toHex())
    }

    public generateTable() {
        let tableDone = 0;

        while (tableDone < this.n) {
            let wlog = this.generateRandomInteger(this.secretSize)
            let w = this.mulBasePoint(wlog)

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
                wlog = wlog + this.table.slog[h]
                w = this.addPoints(w, this.table.s[h])
            }
        }

        // this.initS()
    }

    async solveDLP(pubKey: bigint, numberOfThreads: number = navigator.hardwareConcurrency || 1): Promise<bigint> {
        const workerData = new WorkerData(this.secretSize, pubKey, this.w, this.r, this.table.slog, this.table.s, this.table.table);

        let workers: Worker[] = []
        for (let i = 0; i < numberOfThreads; i++) {
            const worker = new Worker(new URL('./worker.ts', import.meta.url));
            workers.push(worker)
            worker.postMessage(workerData);
        }

        let result = await Utils.waitForAnyWorker(workers);
        Utils.terminateWorkers(workers)

        return result
    }

    async writeJsonToServer() {
        const tableJSON = this.table.writeJson(this.w, this.n, this.secretSize)

        await fetch('http://localhost:3000/upload', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json', 
            },
            body: tableJSON,
        })
    }

    async readJsonFromServer(): Promise<boolean> {
        const response = await fetch(`http://localhost:3000/table?file_name=output_${this.w.toString()}_${this.n}_${this.secretSize}.json`)
        
        if (!response.ok) {
            return false
        }
        
        this.table.readJson(JSON.stringify(await response.json()))
        return true
    }

    async writeLogsToServer(text: string) {
        await fetch('http://localhost:3000/log', {
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
