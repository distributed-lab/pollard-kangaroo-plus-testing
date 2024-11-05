import { Utils } from "../utils"
import { secp256k1 } from "@noble/curves/secp256k1";

onmessage = (e) => {
    const workerData = e.data

    while(true) {
        let wdist = Utils.generateRandomInteger(workerData.secretSize)
        let w = Utils.addPointsSecp256k1(workerData.pubKey, Utils.uint8ArrayToBigInt(secp256k1.getPublicKey(wdist)))

        for (let loop = 0; loop < 8n * workerData.w; loop++) {
            if (Utils.isDistinguished(w, workerData.w)) {
                const tableEntry = workerData.table.get(w)

                if (tableEntry != undefined) {
                    wdist = tableEntry - wdist
                }

                break
            } 

            const h = Utils.hash(w, workerData.r)                
            wdist = wdist + workerData.slog[h]                
            w = Utils.addPointsSecp256k1(w, workerData.s[h])
        }

        if (Utils.uint8ArrayToBigInt(secp256k1.getPublicKey(wdist)) == workerData.pubKey) {
            postMessage(wdist)
            return
        }
    }  
}