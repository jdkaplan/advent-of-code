use std::collections;
use std::str;

fn day1part1() -> i64 {
    let input = include_str!("day1-input.txt");
    let mut freq = 0;
    for line in str::lines(input) {
        match line.parse::<i64>() {
            Ok(d) => freq += d,
            Err(s) => println!("{}", s),
        }
    }
    freq
}

fn day1part2() -> i64 {
    let input = include_str!("day1-input.txt");
    let mut freqs = collections::HashSet::new();
    let mut freq = 0;
    freqs.insert(freq);
    loop {
        for line in str::lines(input) {
            match line.parse::<i64>() {
                Ok(d) => {
                    freq += d;
                    if freqs.contains(&freq) {
                        return freq;
                    }
                    freqs.insert(freq);
                }
                Err(s) => println!("{}", s),
            }
        }
    }
}

fn main() {
    println!("{}", day1part1());
    println!("{}", day1part2());
}
