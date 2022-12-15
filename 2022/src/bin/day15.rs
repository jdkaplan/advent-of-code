use std::collections::HashSet;

use regex::Regex;

const INPUT: &str = include_str!("../../input/day15.txt");

fn main() {
    println!("{}", part1(INPUT, 2_000_000));
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct Pos {
    x: i32,
    y: i32,
}

impl std::fmt::Display for Pos {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "({}, {})", self.x, self.y)
    }
}

impl Pos {
    fn new(x: i32, y: i32) -> Self {
        Self { x, y }
    }

    fn distance(&self, other: Pos) -> i32 {
        let dx = self.x - other.x;
        let dy = self.y - other.y;
        dx.abs() + dy.abs()
    }
}

#[derive(Debug, Copy, Clone)]
struct Sensor {
    pos: Pos,
}

#[derive(Debug, Copy, Clone)]
struct Beacon {
    pos: Pos,
}

fn part1(input: &str, yy: i32) -> usize {
    let pairs: Vec<(Sensor, Beacon)> = aoc::lines(input).map(parse_line).collect();

    let relevant: Vec<(Sensor, Beacon)> = pairs
        .iter()
        .cloned()
        .filter(|(s, b)| {
            let d_cover = s.pos.distance(b.pos);
            let d_line = s.pos.distance(Pos::new(s.pos.x, yy));
            d_line <= d_cover
        })
        .collect();

    let mut coverage: HashSet<Pos> = HashSet::new();

    for (s, b) in relevant {
        let d_cover = s.pos.distance(b.pos);
        let d_line = s.pos.distance(Pos::new(s.pos.x, yy));
        let w_line = d_cover - d_line;

        let x = s.pos.x;
        for dx in 0..=w_line {
            coverage.insert(Pos::new(x + dx, yy));
            coverage.insert(Pos::new(x - dx, yy));
        }
    }

    for (_, b) in pairs {
        coverage.remove(&b.pos);
    }

    coverage.len()
}

fn parse_line(line: &str) -> (Sensor, Beacon) {
    let re = Regex::new(
        r"Sensor at x=(?P<sx>.*), y=(?P<sy>.*): closest beacon is at x=(?P<bx>.*), y=(?P<by>.*)",
    )
    .unwrap();

    let caps = re.captures(line).unwrap();

    (
        Sensor {
            pos: Pos {
                x: caps.name("sx").unwrap().as_str().parse().unwrap(),
                y: caps.name("sy").unwrap().as_str().parse().unwrap(),
            },
        },
        Beacon {
            pos: Pos {
                x: caps.name("bx").unwrap().as_str().parse().unwrap(),
                y: caps.name("by").unwrap().as_str().parse().unwrap(),
            },
        },
    )
}
