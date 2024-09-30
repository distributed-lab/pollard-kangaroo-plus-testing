package generator

const NumberAlphas = 12
const NumberMs = 12
const NumberTames = 4
const NumberRs = 4  // Number of slogs for preprocessing
const NumberDs = 4  // N / T rate
const NumberIs = 24 // Max number of steps

const GeneralNumber = NumberAlphas * NumberMs * NumberTames * NumberRs * NumberDs * NumberIs

const MinAlpha = 0.1
const MaxAlpha = 1.5

const MinM = 0.1
const MaxM = 2

const MinTame = 8192 * 2
const MaxTame = 65536

const MinR = 64
const MaxR = 256

const MinD = 1
const MaxD = 12

const MinI = 4
const MaxI = 64
