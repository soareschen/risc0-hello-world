use risc0_binfmt::{MemoryImage, Program};
use risc0_zkvm::{
    default_prover,
    serde::{from_slice, to_vec},
    sha::Digest,
    ExecutorEnv, Receipt,
};
use risc0_zkvm_platform::PAGE_SIZE;
use std::fs;

pub fn load_zk_program(path: &str) -> (Vec<u8>, Digest) {
    let content = fs::read(path).unwrap();
    let program = Program::load_elf(&content, 0x0C00_0000 as u32).unwrap();
    let image = MemoryImage::new(&program, PAGE_SIZE as u32).unwrap();
    let id = image.compute_id();

    (content, id)
}

pub fn multiply(program: &[u8], a: u64, b: u64) -> (Receipt, u64) {
    let env = ExecutorEnv::builder()
        // Send a & b to the guest
        .add_input(&to_vec(&a).unwrap())
        .add_input(&to_vec(&b).unwrap())
        .build()
        .unwrap();

    // Obtain the default prover.
    let prover = default_prover();

    // Produce a receipt by proving the specified ELF binary.
    let receipt = prover.prove_elf(env, program).unwrap();

    // Extract journal of receipt (i.e. output c, where c = a * b)
    let c: u64 = from_slice(&receipt.journal).expect(
        "Journal output should deserialize into the same types (& order) that it was written",
    );

    // Report the product
    println!("I know the factors of {}, and I can prove it!", c);

    (receipt, c)
}

fn main() {
    let (program, digest) = load_zk_program("./result/multiply");

    let (receipt, result) = multiply(&program, 17, 23);

    assert_eq!(17 * 23, result);

    // Here is where one would send 'receipt' over the network...

    // Verify receipt, panic if it's wrong
    receipt.verify(digest).expect(
        "Code you have proven should successfully verify; did you specify the correct image ID?",
    );
}
