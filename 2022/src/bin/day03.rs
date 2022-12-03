use std::collections::HashSet;

use itertools::Itertools;

const INPUT: &str = include_str!("../../input/day03.txt");

fn main() {
    println!("{}", part1(INPUT));
    println!("{}", part2(INPUT));
}

fn part1(input: &str) -> usize {
    let mut sum = 0;
    for line in input.split('\n').filter(|l| !l.is_empty()) {
        let mid = line.len() / 2;

        let l = &line[..mid];
        let r = &line[mid..];

        let first: HashSet<char> = l.chars().collect();
        let second: HashSet<char> = r.chars().collect();

        let shared = first.intersection(&second).next().unwrap();
        sum += priority(shared);
    }
    sum
}

const ALPHABET: &str = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

fn priority(c: &char) -> usize {
    1 + ALPHABET.chars().position(|x| x == *c).unwrap_or_default()
}

fn part2(input: &str) -> usize {
    let mut sum = 0;
    let lines = input.split('\n').filter(|l| !l.is_empty());
    for group in &lines.chunks(3) {
        let sets: Vec<HashSet<char>> = group
            .map(|rucksack| rucksack.chars().collect::<HashSet<char>>())
            .collect();

        let mut shared = sets[0].clone();
        shared = shared.intersection(&sets[1]).cloned().collect();
        shared = shared.intersection(&sets[2]).cloned().collect();

        let badge = shared.iter().next().unwrap();

        sum += priority(badge);
    }
    sum
}
