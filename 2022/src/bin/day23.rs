use std::collections::{HashMap, HashSet};

const INPUT: &str = include_str!("../../input/day23.txt");

fn main() {
    let grove = Grove::parse(INPUT);

    simulate(grove);
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct RC {
    r: i64,
    c: i64,
}

impl RC {
    const ORIGIN: Self = Self { r: 0, c: 0 };

    fn new(r: i64, c: i64) -> Self {
        Self { r, c }
    }

    fn unsigned(r: usize, c: usize) -> Self {
        Self::new(r.try_into().unwrap(), c.try_into().unwrap())
    }


    #[rustfmt::skip]
    fn neighbors() -> Vec<(i64, i64)> {
        vec![
            (-1, -1), (-1,  0), (-1,  1),
            ( 0, -1),           ( 0,  1),
            ( 1, -1), ( 1,  0), ( 1,  1),
        ]
    }

    fn north() -> Vec<(i64, i64)> {
        vec![(-1, -1), (-1, 0), (-1, 1)]
    }

    fn south() -> Vec<(i64, i64)> {
        vec![(1, -1), (1, 0), (1, 1)]
    }

    fn west() -> Vec<(i64, i64)> {
        vec![(-1, -1), (0, -1), (1, -1)]
    }

    fn east() -> Vec<(i64, i64)> {
        vec![(-1, 1), (0, 1), (1, 1)]
    }

    fn toward_north(&self) -> RC {
        RC::new(self.r - 1, self.c)
    }

    fn toward_south(&self) -> RC {
        RC::new(self.r + 1, self.c)
    }

    fn toward_east(&self) -> RC {
        RC::new(self.r, self.c + 1)
    }

    fn toward_west(&self) -> RC {
        RC::new(self.r, self.c - 1)
    }
}

#[derive(Debug, Clone)]
struct Grove {
    grid: HashSet<RC>,
}

impl Grove {
    fn parse(input: &str) -> Self {
        let mut grid = HashSet::new();

        for (r, line) in input.lines().enumerate() {
            for (c, fill) in line.chars().enumerate() {
                match fill {
                    '.' => continue,
                    '#' => grid.insert(RC::unsigned(r, c)),
                    other => panic!("{:?}", other),
                };
            }
        }

        Self { grid }
    }

    fn propose(&self, from: RC, round: usize) -> Option<RC> {
        if !self.has_elves(&from, &RC::neighbors()) {
            return None;
        }

        let mut props: Vec<(RC, Vec<(i64, i64)>)> = vec![
            (from.toward_north(), RC::north()),
            (from.toward_south(), RC::south()),
            (from.toward_west(), RC::west()),
            (from.toward_east(), RC::east()),
        ];

        props.rotate_left(round % 4);

        for (dest, neighbors) in props {
            if !self.has_elves(&from, &neighbors) {
                return Some(dest);
            }
        }

        None
    }

    fn has_elf(&self, loc: &RC) -> bool {
        self.grid.contains(loc)
    }

    fn has_elves(&self, RC { r, c }: &RC, deltas: &[(i64, i64)]) -> bool {
        deltas
            .iter()
            .any(|&(dr, dc)| self.has_elf(&RC::new(r + dr, c + dc)))
    }

    fn apply(&self, moves: Vec<Move>) -> Self {
        let mut grid = self.grid.clone();

        for Move { from, to } in moves {
            let was_present = grid.remove(&from);
            assert!(was_present);

            let was_empty = grid.insert(to);
            assert!(was_empty);
        }

        Self { grid }
    }
}

#[derive(Debug, Copy, Clone)]
struct Move {
    from: RC,
    to: RC,
}

fn simulate(mut grove: Grove) {
    for round in 0.. {
        let mut proposals: HashMap<RC, Vec<RC>> = HashMap::new();
        for &src in &grove.grid {
            let Some(dest) = grove.propose(src, round) else { continue };
            proposals
                .entry(dest)
                .and_modify(|v| v.push(src))
                .or_insert_with(|| vec![src]);
        }

        let mut moves: Vec<Move> = vec![];
        for (dest, sources) in proposals {
            if sources.len() != 1 {
                continue;
            }

            let src = sources[0];
            moves.push(Move {
                from: src,
                to: dest,
            });
        }

        let done = moves.is_empty();

        grove = grove.apply(moves);

        if round == 9 {
            println!("Part 1: {}", grove.empty_tiles());
        }

        if done {
            println!("Part 2: {}", round + 1);
            break;
        }
    }
}

impl Grove {
    fn empty_tiles(&self) -> usize {
        let (lo, hi) = self.bounds();

        let rows: usize = (1 + hi.r - lo.r).try_into().unwrap();
        let cols: usize = (1 + hi.c - lo.c).try_into().unwrap();

        (rows * cols) - self.grid.len()
    }

    fn bounds(&self) -> (RC, RC) {
        let (lo, hi) = self
            .grid
            .iter()
            .fold((RC::ORIGIN, RC::ORIGIN), |(lo, hi), RC { r, c }| {
                (
                    RC::new(lo.r.min(*r), lo.c.min(*c)),
                    RC::new(hi.r.max(*r), hi.c.max(*c)),
                )
            });
        (lo, hi)
    }
}

impl std::fmt::Display for Grove {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let (lo, hi) = self.bounds();

        for r in lo.r..=hi.r {
            for c in lo.c..=hi.c {
                let is_origin = (r, c) == (0, 0);
                let is_elf = self.has_elf(&RC { r, c });

                let chr = match (is_origin, is_elf) {
                    (true, true) => 'X',
                    (true, false) => 'O',
                    (false, true) => '#',
                    (false, false) => '.',
                };

                write!(f, "{}", chr)?;
            }
            writeln!(f)?;
        }

        Ok(())
    }
}
