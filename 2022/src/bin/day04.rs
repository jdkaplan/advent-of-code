use std::str::FromStr;

const INPUT: &str = include_str!("../../input/day04.txt");

fn main() {
    println!("{}", part1(INPUT));
    println!("{}", part2(INPUT));
}

#[derive(Debug, Copy, Clone)]
struct Assignment {
    start: usize,
    end: usize,
}

impl FromStr for Assignment {
    type Err = std::convert::Infallible; // just trust me

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let parts: Vec<&str> = s.split('-').collect();
        let start: usize = parts[0].parse().unwrap();
        let end: usize = parts[1].parse().unwrap();
        Ok(Self { start, end })
    }
}

impl Assignment {
    fn contains(&self, other: Self) -> bool {
        self.start <= other.start && other.end <= self.end
    }

    fn overlaps(&self, other: Self) -> bool {
        self.contains(other) || other.contains(*self)
    }

    fn intersect(&self, other: Self) -> Option<Self> {
        use std::cmp::{max, min};
        let start = max(self.start, other.start);
        let end = min(self.end, other.end);

        if start <= end {
            Some(Self { start, end })
        } else {
            None
        }
    }

    fn intersects(&self, other: Self) -> bool {
        self.intersect(other).is_some()
    }
}

fn part1(input: &str) -> usize {
    parse_input(input)
        .iter()
        .filter(|(l, r)| l.overlaps(*r))
        .count()
}

fn parse_input(input: &str) -> Vec<(Assignment, Assignment)> {
    input
        .split('\n')
        .filter(|l| !l.is_empty())
        .map(|line| {
            let parts: Vec<&str> = line.split(',').collect();
            let l = Assignment::from_str(parts[0]).unwrap();
            let r = Assignment::from_str(parts[1]).unwrap();
            (l, r)
        })
        .collect()
}

fn part2(input: &str) -> usize {
    let pairs = parse_input(input);

    pairs.iter().filter(|(l, r)| l.intersects(*r)).count()
}
