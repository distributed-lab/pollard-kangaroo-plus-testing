use std::error::Error;
use std::time::Instant;
use pollard_kangaroo::kangaroo::Kangaroo;
use pollard_kangaroo::table::{Table, TableParams, TableSource};
use pollard_kangaroo::{utils};

fn test(dl_bits: u8, secrets_count: u32) -> Result<(), Box<dyn Error>> {
    let (w, n, r) = match dl_bits {
        16 => (8, 8000, 64),
        32 => (2048, 4000, 128),
        48 => (65536, 40000, 128),
        _ => return Err("unsupported dl_bits".into()),
    };

    let table_path = format!("../table-server/output_{}_{}_{}_{}.json", w, n, dl_bits, r);
    let table_source = TableSource::File(table_path);
    let table_params = TableParams::load(table_source)?;

    let table = Table::new(table_params);
    
    let kangaroo = Kangaroo::new(n, w, r, dl_bits, table);

    let mut time = 0;
    
    for _ in 0..secrets_count {
        let now = Instant::now();
        
        let (sk, pk) = utils::generate_keypair(dl_bits);

        println!("Secret key: {:?}", hex::encode(&sk.to_bytes()));
        println!("Public key: {:?}", hex::encode(&pk.as_bytes()));

        let expected_sk = kangaroo.solve_dlp(&pk.decompress().unwrap());

        println!("Expected secret key: {:?}", expected_sk);
        println!("Actual secret key: {:?}", utils::scalar_to_u64(&sk));

        let elapsed = now.elapsed();

        println!("Elapsed: {:.2?}", elapsed.as_millis());
        
        time += elapsed.as_millis();
    }

    println!("Average time: {:.2?}", time as f64 / secrets_count as f64);
    
    Ok(())
}

fn main() -> Result<(), Box<dyn Error>> {
    //test(16, 1)?;
    test(48, 200)?;

    Ok(())
}
