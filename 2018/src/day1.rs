use std::collections;
use std::str;

const INPUT: &str = include_str!("input/day1.txt");

pub fn part1() -> i64 {
    let mut freq = 0;
    for line in str::lines(INPUT) {
        match line.parse::<i64>() {
            Ok(d) => freq += d,
            Err(s) => println!("{}", s),
        }
    }
    freq
}

pub fn part2() -> i64 {
    let mut freqs = collections::HashSet::new();
    let mut freq = 0;
    freqs.insert(freq);
    loop {
        for line in str::lines(INPUT) {
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
