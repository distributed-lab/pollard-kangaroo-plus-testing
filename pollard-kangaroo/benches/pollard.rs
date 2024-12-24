use criterion::{criterion_group, criterion_main, Criterion};
use pollard_kangaroo::kangaroo::Kangaroo;
use pollard_kangaroo::table::{Table, TableParams, TableSource};
use pollard_kangaroo::utils;

fn bench_kangaroo(c: &mut Criterion) {
    let (dl_bits, w, n, r) = (32, 2048, 4000, 128);

    let table_path = format!("../table-server/output_{}_{}_{}_{}.json", w, n, dl_bits, r);
    let table_source = TableSource::File(table_path);
    let table_params = TableParams::load(table_source).unwrap();
    let table = Table::new(table_params);
    let kangaroo = Kangaroo::new(n, w, r, dl_bits, table);
    
    c.bench_function("kangaroo_bench", |b| {
        b.iter(|| {
            let (sk, pk) = utils::generate_keypair(dl_bits);
            kangaroo.solve_dlp(&pk.decompress().unwrap());
        });
    });
}

criterion_group!(benches, bench_kangaroo);
criterion_main!(benches);