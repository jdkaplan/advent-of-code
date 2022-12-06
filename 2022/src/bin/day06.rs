use std::collections::HashSet;

const INPUT: &str = include_str!("../../input/day06.txt");

fn main() {
    println!("{}", part1(INPUT));
    println!("{}", part2(INPUT));
}

fn part1(input: &str) -> usize {
    let sig: Vec<char> = input.trim().chars().collect();
    find_marker(4, sig)
}

fn part2(input: &str) -> usize {
    let sig: Vec<char> = input.trim().chars().collect();
    find_marker(14, sig)
}

fn all_different(c: &[char]) -> bool {
    c.iter().cloned().collect::<HashSet<char>>().len() == c.len()
}

fn find_marker(width: usize, v: Vec<char>) -> usize {
    for i in 0..(v.len()) {
        let buf = &v[i..(i + width)];
        if all_different(buf) {
            return i + width;
        }
    }

    0
}
