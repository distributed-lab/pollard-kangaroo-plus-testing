use wasm_bindgen::prelude::*;

use crate::kangaroo::Kangaroo;
use crate::table::{Table, TableEntry, TableParams};
use crate::utils;

#[wasm_bindgen]
pub struct WASMKangaroo(Kangaroo);

#[wasm_bindgen]
pub fn create_kangaroo(
    s: Vec<js_sys::Uint8Array>,
    slog: Vec<js_sys::Uint8Array>,
    table_point: Vec<js_sys::Uint8Array>,
    table_value: Vec<js_sys::Uint8Array>,
    n: u64,
    w: u64,
    r: u64,
    bits: u8,
) -> Result<WASMKangaroo, JsError> {
    let table_params = TableParams {
        s: s.into_iter().map(|x| hex::encode(x.to_vec())).collect(),
        slog: slog.into_iter().map(|x| hex::encode(x.to_vec())).collect(),
        table: table_point
            .into_iter()
            .zip(table_value.into_iter())
            .map(|(point, value)| TableEntry {
                point: hex::encode(point.to_vec()),
                value: hex::encode(value.to_vec()),
            })
            .collect(),
    };
    let table = Table::new(table_params);

    Ok(WASMKangaroo(Kangaroo::new(n, w, r, bits, table)))
}

#[wasm_bindgen]
impl WASMKangaroo {
    pub fn solve_dlp(&self, pk: Vec<u8>) -> u64 {
        let pk = utils::slice_to_point(pk).decompress().unwrap();

        self.0.solve_dlp(&pk)
    }
}
