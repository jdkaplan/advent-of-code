use std::collections::HashSet;

const INPUT: &str = include_str!("../../input/day06.txt");

fn main() {
    println!("{}", part1(INPUT));
    println!("{}", part2(INPUT));
}

fn part1(input: &str) -> usize {
    let sig: Vec<char> = input.trim().chars().collect();

    for i in 0..(sig.len()) {
        let buf = &sig[i..(i + 4)];
        if all_different(buf) {
            return i + 4;
        }
    }

    0
}

fn all_different(c: &[char]) -> bool {
    c.iter().cloned().collect::<HashSet<char>>().len() == c.len()
}

fn part2(input: &str) -> usize {
    let sig: Vec<char> = input.trim().chars().collect();

    for i in 0..(sig.len()) {
        let buf = &sig[i..(i + 14)];
        if all_different(buf) {
            return i + 14;
        }
    }

    0
}
