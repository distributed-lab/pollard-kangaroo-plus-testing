import { RistrettoPoint } from '@noble/curves/ed25519';

type RistPoint = InstanceType<typeof RistrettoPoint>;

/**
 * Compute the ceiling of the square root of n.
 * This uses a numeric conversion for simplicity. For extremely large `n`,
 * a more robust method would be needed.
 */
function bigintSqrtCeil(n: bigint): bigint {
  const x = BigInt(Math.floor(Math.sqrt(Number(n))));
  return (x * x === n) ? x : x + 1n;
}

/**
 * Convert a RistrettoPoint to a string key (hex encoding) suitable for Map lookup.
 */
function pointToHex(p: RistPoint): string {
  return Buffer.from(p.toRawBytes()).toString('hex');
}

/**
 * Baby-step Giant-step algorithm for Ristretto groups
 * 
 * Given points A and B in a Ristretto group with known order n,
 * find x such that x*A = B.
 *
 * @param A Base point of the group (like a generator)
 * @param B Target point we want to express as x*A
 * @param n Order of the group (e.g. ed25519.CURVE.n for Ristretto)
 * @returns x if a solution is found, otherwise undefined
 */
export function babyStepGiantStepRistretto(A: RistPoint, B: RistPoint, n: bigint): bigint | undefined {
  // m = ceil(sqrt(n))
  const m = bigintSqrtCeil(n);

  // Baby steps: store i*A for i in [0, m-1]
  const babyMap = new Map<string, bigint>();
  let current = RistrettoPoint.ZERO;
  for (let i = 0n; i < m; i++) {
    const key = pointToHex(current);
    // Store i as the discrete log of current relative to A
    babyMap.set(key, i);
    current = current.add(A);
  }

  // Giant step factor: M*A
  const MA = A.multiply(m);

  // Giant steps: for j in [0, m-1], compute B - j*(M*A) and check if it matches a baby step
  let giant = B;
  for (let j = 0n; j < m; j++) {
    const key = pointToHex(giant);
    if (babyMap.has(key)) {
      const i = babyMap.get(key)!;
      // x = i + j*m
      return i + j * m;
    }
    giant = giant.subtract(MA);
  }

  // No solution found
  return undefined;
}