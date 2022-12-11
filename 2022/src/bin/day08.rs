use std::collections::{HashMap, HashSet};

const INPUT: &str = include_str!("../../input/day08.txt");

fn main() {
    let grid = Grid::new(INPUT);

    let visibility = grid.find_visible();
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
        let lines: Vec<&str> = aoc::lines(text).collect();

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

    fn find_visible(&self) -> HashMap<RC, HashSet<Visibility>> {
        // Assume all trees are visible from all sides until we learn that they're blocked.
        let mut visibility: HashMap<RC, HashSet<Visibility>> = HashMap::new();

        for (r, c) in itertools::iproduct!(0..self.rows, 0..self.cols) {
            visibility.insert((r, c), Visibility::all());
        }

        // Now see what each tree would block.
        for (r1, c1) in itertools::iproduct!(0..self.rows, 0..self.cols) {
            let height = self.map[&(r1, c1)];

            use Visibility::*;
            let block: Vec<(Visibility, Vec<RC>)> = vec![
                (Top, (0..r1).map(|r| (r, c1)).collect()),
                (Bottom, ((r1 + 1)..self.rows).map(|r| (r, c1)).collect()),
                (Right, (0..c1).map(|c| (r1, c)).collect()),
                (Left, ((c1 + 1)..self.cols).map(|c| (r1, c)).collect()),
            ];

            for (vis, ray) in block {
                for rc in ray {
                    if height >= self.map[&rc] {
                        visibility.entry(rc).and_modify(|v| {
                            v.remove(&vis);
                        });
                    }
                }
            }
        }

        visibility
    }

    fn score_views(&self) -> HashMap<RC, usize> {
        let mut scene: HashMap<RC, usize> = HashMap::new();

        for (r1, c1) in itertools::iproduct!(0..self.rows, 0..self.cols) {
            let height = self.map[&(r1, c1)];

            let mut score = 1;

            let blockage = |rc: &RC| -> bool { self.map[rc] >= height };

            let up = (0..r1).rev().map(|r| (r, c1));
            score *= take_until(up, blockage).len();

            let down = ((r1 + 1)..self.rows).map(|r| (r, c1));
            score *= take_until(down, blockage).len();

            let left = (0..c1).rev().map(|c| (r1, c));
            score *= take_until(left, blockage).len();

            let right = ((c1 + 1)..self.cols).map(|c| (r1, c));
            score *= take_until(right, blockage).len();

            scene.insert((r1, c1), score);
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
