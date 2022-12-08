use std::collections::{HashMap, HashSet};

const INPUT: &str = include_str!("../../input/day08.txt");

fn main() {
    let grid = Grid::new(INPUT);

    let visibility = grid.count_visible();
    let part1 = visibility.iter().filter(|(_, v)| !v.is_empty()).count();
    println!("Part 1: {}", part1);

    let scenicality = grid.score_views();
    let part2 = *scenicality.values().max().unwrap();
    println!("Part 2: {}", part2);
}

type RC = (usize, usize);

struct Grid {
    map: HashMap<RC, u8>,
    rows: usize,
    cols: usize,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
enum Visibility {
    Top,
    Bottom,
    Left,
    Right,
}

impl Visibility {
    fn all() -> HashSet<Self> {
        use Visibility::*;
        HashSet::from([Top, Bottom, Left, Right])
    }
}

impl Grid {
    fn new(text: &str) -> Self {
        let mut map = HashMap::new();
        let lines = aoc::split_lines(text);

        let rows = lines.len();
        let cols = lines[0].len();

        for (row, line) in lines.iter().enumerate() {
            for (col, num) in line.chars().enumerate() {
                let height: u8 = num.to_string().parse().unwrap();
                map.insert((row, col), height);
            }
        }
        Self { map, rows, cols }
    }

    fn count_visible(&self) -> HashMap<RC, HashSet<Visibility>> {
        // Assume all trees are visible from all sides until we learn that they're blocked.
        let mut visibility: HashMap<RC, HashSet<Visibility>> = HashMap::new();

        for r in 0..self.rows {
            for c in 0..self.cols {
                visibility.insert((r, c), Visibility::all());
            }
        }

        for (r1, c1) in itertools::iproduct!(0..self.rows, 0..self.cols) {
            let big = (r1, c1);
            let h1 = self.map[&big];

            for (r2, c2) in (0..r1).map(|r| (r, c1)) {
                let lil = (r2, c2);
                let h2 = self.map[&lil];

                if h1 >= h2 {
                    visibility.entry(lil).and_modify(|v| {
                        v.remove(&Visibility::Bottom);
                    });
                }
            }

            for (r2, c2) in ((r1 + 1)..self.rows).map(|r| (r, c1)) {
                let lil = (r2, c2);
                let h2 = self.map[&lil];

                if h1 >= h2 {
                    visibility.entry(lil).and_modify(|v| {
                        v.remove(&Visibility::Top);
                    });
                }
            }

            for (r2, c2) in (0..c1).map(|c| (r1, c)) {
                let lil = (r2, c2);
                let h2 = self.map[&lil];

                if h1 >= h2 {
                    visibility.entry(lil).and_modify(|v| {
                        v.remove(&Visibility::Right);
                    });
                }
            }

            for (r2, c2) in ((c1 + 1)..self.cols).map(|c| (r1, c)) {
                let lil = (r2, c2);
                let h2 = self.map[&lil];

                if h1 >= h2 {
                    visibility.entry(lil).and_modify(|v| {
                        v.remove(&Visibility::Left);
                    });
                }
            }
        }

        visibility
    }

    fn score_views(&self) -> HashMap<RC, u64> {
        let mut scene: HashMap<RC, u64> = HashMap::new();

        for (r1, c1) in itertools::iproduct!(0..self.rows, 0..self.cols) {
            let big = (r1, c1);
            let h1 = self.map[&big];

            let mut score = 1;

            let up = (0..r1).rev().map(|r| (r, c1));
            score *= take_until(up, |rc| self.map[rc] >= h1).len();

            let down = ((r1 + 1)..self.rows).map(|r| (r, c1));
            score *= take_until(down, |rc| self.map[rc] >= h1).len();

            let left = (0..c1).rev().map(|c| (r1, c));
            score *= take_until(left, |rc| self.map[rc] >= h1).len();

            let right = ((c1 + 1)..self.cols).map(|c| (r1, c));
            score *= take_until(right, |rc| self.map[rc] >= h1).len();

            scene.insert(big, score as u64);
        }

        scene
    }
}

// This iterator is eager because _I'm_ lazy.
fn take_until<P>(mut iter: impl Iterator<Item = RC>, mut predicate: P) -> Vec<RC>
where
    P: FnMut(&RC) -> bool,
{
    let mut v = vec![];
    loop {
        let Some(i) = iter.next() else { break };
        v.push(i);

        if predicate(&i) {
            break;
        }
    }
    v
}
