use std::error::Error;
use curve25519_dalek_ng::ristretto::{CompressedRistretto, RistrettoPoint};
use curve25519_dalek_ng::scalar::Scalar;
use serde::Deserialize;
use crate::utils;

#[derive(Debug, Deserialize)]
pub struct TableEntry {
    pub point: String,
    pub value: String,
}

#[derive(Debug, Deserialize)]
pub struct TableParams {
    pub s: Vec<String>,
    pub slog: Vec<String>,
    pub table: Vec<TableEntry>
}

pub enum TableSource {
    File(String),
    Network(String),
}

impl TableParams {
    pub fn load(source: TableSource) -> Result<TableParams, Box<dyn Error>> {
        let data = match source {
            TableSource::File(path) => std::fs::read_to_string(path)?,
            TableSource::Network(url) => reqwest::blocking::get(&url)?.text()?
        };

        Ok(serde_json::from_str(&data)?)
    }
}

struct TableEntryInternal {
    point: CompressedRistretto,
    value: Scalar,
}

pub struct Table {
    s: Vec<RistrettoPoint>,
    slog: Vec<Scalar>,
    table: Vec<TableEntryInternal>,
}

impl Table {
    pub fn new(params: TableParams) -> Table {
        let s = params.s
            .into_iter()
            .map(|x| utils::hex_string_to_point(x).decompress().unwrap())
            .collect();
        let slog = params.slog
            .into_iter()
            .map(utils::hex_string_to_scalar)
            .collect();
        let mut table = params.table
            .into_iter()
            .map(|x| TableEntryInternal {
                point: utils::hex_string_to_point(x.point),
                value: utils::hex_string_to_scalar(x.value),
            })
            .collect::<Vec<_>>();

        // FIXME: should we make sure that there are no point duplicates?
        table.sort_by(|a, b| a.point.as_bytes().cmp(b.point.as_bytes()));

        Table { s, slog, table }
    }

    pub fn s(&self, i: usize) -> RistrettoPoint {
        self.s[i]
    }
    
    pub fn slog(&self, i: usize) -> Scalar {
        self.slog[i]
    }
    
    pub fn value(&self, point: &CompressedRistretto) -> Option<Scalar> {
        match self.table.binary_search_by(|x| x.point.as_bytes().cmp(point.as_bytes())) {
            Ok(i) => Some(self.table[i].value),
            Err(_) => None,
        }
    }
}
