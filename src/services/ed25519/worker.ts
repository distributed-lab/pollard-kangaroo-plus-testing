import { Utils } from "../utils"
import { ed25519 } from "@noble/curves/ed25519";
import { ExtPointType } from "@noble/curves/abstract/edwards";

onmessage = (e) => {
    const workerData = e.data

    while(true) {
        let wdist = Utils.generateRandomInteger(workerData.secretSize-8)

        const p = ed25519.ExtendedPoint.BASE.multiply(wdist)
        ed25519.ExtendedPoint.BASE.add(p);
        console.log(ed25519.ExtendedPoint.fromHex("004769f87c15c73e3b24ebe49d645818ec98ea27275e489a07ea336fcf6818b9"))

        let a: ExtPointType = workerData.pubKey;
        console.log((<ExtPointType>a))
        let w = Utils.add(workerData.pubKey, p) //workerData.pubKey.add(p)
        let wBig = Utils.extendedPointToBigInt(w)
        // w.toAffine().y

        for (let loop = 0; loop < 6n * workerData.w; loop++) {
            if (Utils.isDistinguished(wBig, workerData.w)) {
                const tableEntry = workerData.table.get(wBig)

                if (tableEntry != undefined) {
                    wdist = tableEntry - wdist

                    // if (Utils.mulBasePointEd25519(wdist) == workerData.pubKey) {
                        postMessage(wdist)
                        return wdist
                    // }
                }

                break
            } 

            const h = Utils.hash(wBig, workerData.r)         
            wdist = wdist + workerData.slog[h]    
            
            // w = Utils.addPointsEd25519(w, this.table.s[h])
            w = w.add(workerData.s[h])
            wBig = Utils.extendedPointToBigInt(w)
        }
    }
}