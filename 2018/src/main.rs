use std::str;

fn main() {
    let input = include_str!("day1-input.txt");
    let mut freq = 0;
    for line in str::lines(input) {
        match line.parse::<i32>() {
            Ok(d) => freq += d,
            Err(s) => println!("{}", s),
        }
    }
    println!("{}", freq);
}
