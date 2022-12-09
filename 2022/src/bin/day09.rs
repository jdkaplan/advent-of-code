use std::{collections::HashSet, str::FromStr};

use serde::{
    de::{value, IntoDeserializer},
    Deserialize,
};

const INPUT: &str = include_str!("../../input/day09.txt");

fn main() {
    println!("{}", part1(INPUT));
}

fn part1(input: &str) -> usize {
    let steps = parse_input(input);

    let num_knots = 10;
    let tail = num_knots - 1;

    let mut knots = vec![RC::new(0, 0); num_knots];

    let mut tail_visited: HashSet<RC> = HashSet::new();
    tail_visited.insert(knots[tail]);

    // render(&knots, &tail_visited);
    for step in steps {
        println!("> {:?}, {}", step.d, step.n);

        for _ in 0..(step.n) {
            knots[0] = knots[0].mv(step.d.delta());
            for i in 1..(knots.len()) {
                knots[i] = knots[i].follow(knots[i - 1]);
            }
            // dbg!(head);
            // dbg!(tail);

            tail_visited.insert(knots[tail]);

            // render(&knots, &tail_visited);
        }

        // render(&knots, &tail_visited);
        // std::thread::sleep(std::time::Duration::from_millis(500));
    }

    render(&knots, &tail_visited);
    tail_visited.len()
}

fn parse_input(input: &str) -> Vec<Step> {
    aoc::split_lines(input)
        .iter()
        .map(|line| {
            let words = aoc::split_words(line);

            let d = Direction::from_str(words[0]).unwrap();
            let n = words[1].parse::<i64>().unwrap();

            Step { d, n }
        })
        .collect()
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct Step {
    d: Direction,
    n: i64,
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

    fn follow(&self, head: RC) -> RC {
        // dbg!(head.r);
        // dbg!(head.c);
        // dbg!(self.r);
        // dbg!(self.c);

        let dr = head.r - self.r;
        let dc = head.c - self.c;

        // dbg!(dr);
        // dbg!(dc);

        // Adjacent
        if dr.abs() < 2 && dc.abs() < 2 {
            // dbg!("OK");
            return *self;
        }

        // dbg!(sign(dr));
        // dbg!(sign(dc));

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
