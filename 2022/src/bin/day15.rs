use std::collections::HashSet;

use regex::Regex;

// const INPUT: (&str, i32, i32) = (include_str!("../../input/day15-ex.txt"), 10, 20);
const INPUT: (&str, i32, i32) = (include_str!("../../input/day15.txt"), 2_000_000, 4_000_000);

fn main() {
    let (input, y, max) = INPUT;
    println!("Part 1: {}", part1(input, y));
    println!("Part 2: {}", part2(input, max));
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

    let mut coverage: HashSet<Pos> = HashSet::new();

    for (s, b) in &pairs {
        let d_cover = s.pos.distance(b.pos);
        let dy = s.pos.distance(Pos::new(s.pos.x, yy));
        let width = d_cover - dy;

        let x = s.pos.x;
        for dx in 0..=width {
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

#[derive(Debug, Copy, Clone)]
struct Range {
    start: i32,
    end: i32,
}

impl Range {
    fn new(start: i32, end: i32) -> Self {
        Self { start, end }
    }

    fn union(&self, other: &Self) -> Option<Self> {
        let adjacent = self.end + 1 >= other.start;
        if adjacent {
            use std::cmp::{max, min};
            let start = min(self.start, other.start);
            let end = max(self.end, other.end);
            Some(Self { start, end })
        } else {
            None
        }
    }

    fn merge_left(mut rs: Vec<Self>) -> Self {
        rs.sort_by_key(|r| r.start);

        let mut merged = rs[0];

        for r in rs[1..].iter() {
            if let Some(new) = merged.union(r) {
                merged = new;
            } else {
                break;
            }
        }
        merged
    }

    fn len(&self) -> i32 {
        1 + self.end - self.start
    }
}

#[derive(Debug, Clone)]
struct Coverage {
    ranges: Vec<Range>,
    max: i32,
}

impl Coverage {
    fn new(max: i32) -> Self {
        Self {
            ranges: vec![],
            max,
        }
    }

    fn insert(&mut self, r: Range) {
        // Clip!
        let r = Range {
            start: r.start.max(0),
            end: r.end.min(self.max),
        };

        if r.start <= r.end {
            self.ranges.push(r);
        }
    }

    fn defrag(&self) -> Option<i32> {
        let merged = Range::merge_left(self.ranges.clone());
        if merged.len() == self.max + 1 {
            None
        } else {
            Some(merged.end + 1)
        }
    }
}

fn part2(input: &str, max: i32) -> i64 {
    let pairs: Vec<(Sensor, Beacon)> = aoc::lines(input).map(parse_line).collect();

    for yy in 0..=max {
        let mut coverage = Coverage::new(max);

        for (s, b) in &pairs {
            let d_cover = s.pos.distance(b.pos);

            let projected = Pos::new(s.pos.x, yy);
            let dy = s.pos.distance(projected);
            let dx = d_cover - dy;

            if dx < 0 {
                continue;
            }

            let x = s.pos.x;
            let r = Range::new(x - dx, x + dx);

            coverage.insert(r);
        }

        if let Some(xx) = coverage.defrag() {
            return 4_000_000 * (xx as i64) + (yy as i64);
        }
    }

    panic!("No solution? Must be the input! :P")
}
