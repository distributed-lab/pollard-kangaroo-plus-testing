use wasm_bindgen::prelude::*;

use crate::kangaroo::Kangaroo;
use crate::table::{Table, TableEntry, TableParams};
use crate::utils;

#[wasm_bindgen]
pub struct WASMKangaroo(Kangaroo);

#[wasm_bindgen]
pub fn create_kangaroo(
    table_object: JsValue,
    n: u64,
    w: u64,
    r: u64,
    bits: u8,
) -> Result<WASMKangaroo, JsError> {
    let table_params: TableParams = serde_wasm_bindgen::from_value(table_object)?;
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
