use rand::Rng;

fn main() {
    let mut rng = rand::rng();
    let random_number: u32 = rng.random_range(1..=100);
    println!("Generated random number: {}", random_number);
}
