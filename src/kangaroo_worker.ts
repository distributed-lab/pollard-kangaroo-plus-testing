const WorkerPool = require('workerpool')

// const bcryptHashh = (thread) => {
//   let sum = 0;
//   for (let i = 0; i < 1000000 * thread; i++) {
//     // console.log(thread + " - " + i)
//     sum += i;
//   }
//   return sum
// }

const sharedTabledoneBuffer = new SharedArrayBuffer(4); // 4 bytes for an Int32
const sharedTabledoneArray = new Int32Array(sharedTabledoneBuffer);


function generateTableThread(thread, sharedArray) {
    while (true) {
        Atomics.add(sharedArray, 0, 1);
        if (Atomics.load(sharedArray, 0) >= 100000000) {
            // console.log(Atomics.load(sharedArray, 0))
            console.log("break")
            break
        }
    }
    // console.log(sharedTabledoneArray[0])

}

WorkerPool.worker({
    // bcryptHashh,
    generateTableThread
})