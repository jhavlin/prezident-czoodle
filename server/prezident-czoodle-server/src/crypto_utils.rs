extern crate sha2;

use sha2::{Digest, Sha256};

pub fn sha256(str: &str) -> String {
    let mut hash_helper = Sha256::new();
    // write input message
    hash_helper.update(str);
    // read hash digest and consume hash helper
    let result = hash_helper.finalize();
    let strings: Vec<String> = result.iter().map(|b| format!("{:02x}", b)).collect();
    strings.join("")
}
