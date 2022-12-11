use std::{collections::HashSet, str::FromStr};

use serde::{
    de::{value, IntoDeserializer},
    Deserialize,
};

const INPUT: &str = include_str!("../../input/day09.txt");

fn main() {
    println!("{}", simulate(INPUT, 2));
    println!("{}", simulate(INPUT, 10));
}

fn simulate(input: &str, num_knots: usize) -> usize {
    let steps = parse_input(input);

    let mut knots = vec![RC::new(0, 0); num_knots];
    let tail = num_knots - 1;

    let mut tail_visited: HashSet<RC> = HashSet::new();
    tail_visited.insert(knots[tail]);

    for step in steps {
        for _ in 0..(step.n) {
            knots[0] = knots[0].mv(step.d.delta());
            for i in 1..(knots.len()) {
                knots[i] = knots[i].follow(knots[i - 1]);
            }

            tail_visited.insert(knots[tail]);
        }
    }

    render(&knots, &tail_visited);
    tail_visited.len()
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct Step {
    d: Direction,
    n: i64,
}

fn parse_input(input: &str) -> Vec<Step> {
    aoc::lines(input)
        .map(|line| {
            let words: Vec<&str> = aoc::words(line).collect();

            let d = Direction::from_str(words[0]).unwrap();
            let n = words[1].parse::<i64>().unwrap();

            Step { d, n }
        })
        .collect()
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct RC {
    r: i64,
    c: i64,
}

impl RC {
    fn new(r: i64, c: i64) -> Self {
        Self { r, c }
    }

    fn origin() -> Self {
        Self::new(0, 0)
    }

    fn mv(&self, delta: RC) -> RC {
        RC {
            r: self.r + delta.r,
            c: self.c + delta.c,
        }
    }

    fn follow(&self, target: RC) -> RC {
        let dr = target.r - self.r;
        let dc = target.c - self.c;

        // Adjacent
        if dr.abs() < 2 && dc.abs() < 2 {
            return *self;
        }

        RC::new(self.r + sign(dr), self.c + sign(dc))
    }
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash, Deserialize)]
enum Direction {
    U,
    D,
    L,
    R,
}

impl Direction {
    fn delta(&self) -> RC {
        use Direction::*;
        match self {
            U => RC::new(1, 0),
            D => RC::new(-1, 0),
            L => RC::new(0, -1),
            R => RC::new(0, 1),
        }
    }
}

impl FromStr for Direction {
    type Err = value::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Self::deserialize(s.into_deserializer())
    }
}

fn render(knots: &[RC], tail_visited: &HashSet<RC>) {
    let rcs = knots.iter().chain(tail_visited.iter());
    let (lo, hi) = rcs.fold((RC::origin(), RC::origin()), |(lo, hi), RC { r, c }| {
        (
            RC::new(lo.r.min(*r), lo.c.min(*c)),
            RC::new(hi.r.max(*r), hi.c.max(*c)),
        )
    });

    let chr = move |r: i64, c: i64| -> char {
        for (i, rc) in knots.iter().enumerate() {
            if (r, c) == (rc.r, rc.c) {
                return char::from_digit(i as u32, 10).unwrap();
            }
        }
        if tail_visited.contains(&RC::new(r, c)) {
            '#'
        } else {
            '.'
        }
    };

    // (r, c) is probably something like (-y, x), but it's too late to change that now...
    for r in (lo.r..=hi.r).rev() {
        for c in lo.c..=hi.c {
            print!("{}", chr(r, c));
        }
        println!();
    }
    println!();
}

fn sign(n: i64) -> i64 {
    n.cmp(&0) as i64
}
