import { Utils } from "../utils"

onmessage = (e) => {
    const workerData = e.data

    while(true) {
        let wdist = Utils.generateRandomInteger(workerData.secretSize-8)
        let w = Utils.addPointsEd25519(workerData.pubKey, Utils.mulBasePointEd25519(wdist))

        for (let loop = 0; loop < 8n * workerData.w; loop++) {
            if (Utils.isDistinguished(w, workerData.w)) {
                const tableEntry = workerData.table.get(w)

                if (tableEntry != undefined) {
                    console.log(tableEntry)
                    wdist = tableEntry - wdist
                }

                break
            } 

            const h = Utils.hash(w, workerData.r)                
            wdist = wdist + workerData.slog[h]      
            w = Utils.addPointsEd25519(w, workerData.s[h])
        }
        
        if (Utils.mulBasePointEd25519(wdist) == workerData.pubKey) {
            postMessage(wdist)
            return wdist
        }
    }
}