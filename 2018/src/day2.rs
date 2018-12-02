use std::collections::{HashMap, HashSet};
use std::iter::{Iterator, Zip};
use std::str;

const INPUT: &str = include_str!("input/day2.txt");

type CharCount = HashMap<char, u32>;

fn count_chars(s: &str) -> CharCount {
    let mut counts: HashMap<char, u32> = HashMap::new();
    for c in s.chars() {
        let mut count = counts.entry(c).or_insert(0);
        *count += 1;
    }
    counts
}

fn has_double(cc: &CharCount) -> bool {
    for v in cc.values() {
        if v == &2 {
            return true;
        }
    }
    false
}

fn has_triple(cc: &CharCount) -> bool {
    for v in cc.values() {
        if v == &3 {
            return true;
        }
    }
    false
}

pub fn part1() -> u32 {
    let mut twos = 0;
    let mut threes = 0;
    for line in str::lines(INPUT) {
        let cc = count_chars(line);
        if has_double(&cc) {
            twos += 1;
        }
        if has_triple(&cc) {
            threes += 1;
        }
    }
    twos * threes
}

fn difference_count(s1: &str, s2: &str) -> usize {
    let mut d = 0;
    let mut i1 = s1.chars();
    let mut i2 = s2.chars();

    loop {
        let c1 = i1.next();
        let c2 = i2.next();
        match (c1, c2) {
            (Some(a), Some(b)) => {
                if a != b {
                    d += 1;
                }
            }
            (Some(_), None) => d += 1,
            (None, Some(_)) => d += 1,
            (None, None) => break,
        }
    }
    d
}

fn common_chars<'a>(s1: &'a str, s2: &'a str) -> String {
    let mut common = "".to_owned();
    let mut i1 = s1.chars();
    let mut i2 = s2.chars();

    loop {
        let c1 = i1.next();
        let c2 = i2.next();

        match (c1, c2) {
            (Some(a), Some(b)) => {
                if a == b {
                    common.push(a);
                }
            }
            (Some(_), None) => panic!("s1.len() != s2.len()"),
            (None, Some(_)) => panic!("s1.len() != s2.len()"),
            (None, None) => break,
        }
    }
    common
}

pub fn part2() -> String {
    let mut pairs = HashSet::new();
    for l1 in str::lines(INPUT) {
        for l2 in str::lines(INPUT) {
            pairs.insert((l1, l2));
        }
    }
    for (s1, s2) in pairs {
        if difference_count(s1, s2) == 1 {
            return common_chars(s1, s2);
        }
    }
    panic!("No solution")
}
