use core::ops::{Add, AddAssign, Mul, Sub};
use curve25519_dalek_ng::constants;
use curve25519_dalek_ng::ristretto::{CompressedRistretto, RistrettoPoint};
use crate::table::Table;
use crate::utils;

pub struct Kangaroo {
    #[allow(dead_code)]
    n: u64,
    w: u64,
    r: u64,
    bits: u8,
    table: Table,
}

impl Kangaroo {
    pub fn new(n: u64, w: u64, r: u64, bits: u8, table: Table) -> Kangaroo {
        Kangaroo { n, w, r, bits, table }
    }

    pub fn solve_dlp(&self, pk: &RistrettoPoint) -> u64 {
        loop {
            let mut w_dist = utils::generate_random_scalar(self.bits - 8);
            let mut w = pk.add(constants::RISTRETTO_BASEPOINT_POINT.mul(w_dist));
            let mut w_big = w.compress();

            for _ in 0..8 * self.w {
                if self.is_distinguished(&w_big) {
                    if let Some(table_entry) = self.table.value(&w_big) {
                        let sk = table_entry.sub(w_dist);

                        if constants::RISTRETTO_BASEPOINT_POINT.mul(sk).eq(pk) {
                            return utils::scalar_to_u64(&sk);
                        }
                    }

                    break;
                }

                let h = self.hash(&w_big);

                w_dist.add_assign(&self.table.slog(h));
                w.add_assign(&self.table.s(h));
                w_big = w.compress();
            }
        };
    }

    fn hash(&self, point: &CompressedRistretto) -> usize {
        let point = self.point_to_u64(point);
        (point & (self.r - 1)) as usize
    }

    fn is_distinguished(&self, point: &CompressedRistretto) -> bool {
        let point = self.point_to_u64(point);
        (point & (self.w - 1)) == 0
    }

    fn point_to_u64(&self, p: &CompressedRistretto) -> u64 {
        let (_, u64_bytes) = p.as_bytes().split_at(32 - size_of::<u64>());
        u64::from_be_bytes(u64_bytes.try_into().unwrap())
    }
}
