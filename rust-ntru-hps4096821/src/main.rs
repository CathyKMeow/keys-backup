/*
 * Copyright 2022, Catherine Kelly
 * SPDX-License-Identifier: CC0-1.0 OR Unlicense
 */

#![allow(non_snake_case)]
use ntrust_native::{RNGState};
use ntrust_native::{crypto_kem_dec, crypto_kem_enc, crypto_kem_keypair};
use ntrust_native::{CRYPTO_BYTES, CRYPTO_CIPHERTEXTBYTES, CRYPTO_PUBLICKEYBYTES, CRYPTO_SECRETKEYBYTES};
use hex;

use std;
use std::io::{Read};
use std::error;

struct RNG {}

impl RNGState for RNG {
	fn randombytes(&mut self, x: &mut [u8]) -> Result<(), Box<dyn error::Error>> {
		let mut file = std::fs::File::open("/dev/urandom")?;
		file.read_exact(x)?;
		Ok(())
	}
    fn randombytes_init(&mut self, _entropy_input: [u8; 48]) {}
}

fn main() -> Result<(), Box<dyn error::Error>> {
	let args: Vec<String> = std::env::args().collect();
    let stdin = std::io::stdin();

	let mut rng = RNG {};

	let mut pubKey = [0u8; CRYPTO_PUBLICKEYBYTES];
	let mut privKey = [0u8; CRYPTO_SECRETKEYBYTES];
	let mut encKey = [0u8; CRYPTO_CIPHERTEXTBYTES];
	let mut plainKey = [0u8; CRYPTO_BYTES];

	if  &args[1] == "gen" {
		crypto_kem_keypair(&mut pubKey, &mut privKey, &mut rng)?;
		println!("{} {}", hex::encode(pubKey), hex::encode(privKey));
	}

	if  &args[1] == "enc" {
		let mut pubKeyStr = String::new();
		stdin.read_line(&mut pubKeyStr)?;

		let pubKeyVec = hex::decode(pubKeyStr.trim()).unwrap();
		for i in 0..pubKeyVec.len() {
			pubKey[i] = pubKeyVec[i];
		}

		crypto_kem_enc(&mut encKey, &mut plainKey, &pubKey, &mut rng)?;
		println!("{}", hex::encode(&plainKey));
		println!("{}", hex::encode(&encKey));
	}

	if &args[1] == "dec" {
		let mut privKeyStr = String::new();
		let mut encKeyStr = String::new();
		stdin.read_line(&mut privKeyStr)?;
		stdin.read_line(&mut encKeyStr)?;

		let privKeyVec = hex::decode(privKeyStr.trim()).unwrap();
		for i in 0..privKeyVec.len() {
			privKey[i] = privKeyVec[i];
		}

		let encKeyVec = hex::decode(encKeyStr.trim()).unwrap();
		for i in 0..encKeyVec.len() {
			encKey[i] = encKeyVec[i];
		}

		crypto_kem_dec(&mut plainKey, &mut encKey, &privKey)?;
		println!("{}", hex::encode(&plainKey));
	}

	Ok(())
}
