use std::ops::Mul;
use curve25519_dalek_ng::constants::RISTRETTO_BASEPOINT_POINT;
use curve25519_dalek_ng::ristretto::CompressedRistretto;
use curve25519_dalek_ng::scalar::Scalar;

use rand_core::{OsRng, TryRngCore};

pub fn hex_string_to_scalar(s: String) -> Scalar {
    let mut scalar = hex_string_to_bytes(s);
    scalar.reverse();

    Scalar::from_canonical_bytes(scalar.try_into().unwrap()).unwrap()
}

pub fn hex_string_to_point(s: String) -> CompressedRistretto {
    CompressedRistretto::from_slice(&hex_string_to_bytes(s)[..])
}

pub fn scalar_to_u64(s: &Scalar) -> u64 {
    let (u64_bytes, _) = s.as_bytes().split_at(size_of::<u64>());
    u64::from_le_bytes(u64_bytes.try_into().unwrap())
}

pub fn generate_random_scalar(bits: u8) -> Scalar {
    let mut key = [0u8; 32];
    OsRng.try_fill_bytes(&mut key[0..(bits as usize >> 3)]).unwrap();

    Scalar::from_canonical_bytes(key.try_into().unwrap()).unwrap()
}

pub fn generate_keypair(dl_bits: u8) -> (Scalar, CompressedRistretto) {
    let sk = generate_random_scalar(dl_bits);

    (sk, RISTRETTO_BASEPOINT_POINT.mul(sk).compress())
}

fn hex_string_to_bytes(s: String) -> Vec<u8> {
    hex::decode(format!("{:0>64}", s)).unwrap()
}
