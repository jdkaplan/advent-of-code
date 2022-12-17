use std::{collections::HashSet, convert::TryInto, fmt::Display, str::FromStr};

use serde::{
    de::{value, IntoDeserializer},
    Deserialize,
};

// const INPUT: &str = include_str!("../../input/day17-ex.txt");
const INPUT: &str = include_str!("../../input/day17.txt");

fn main() {
    let jets = parse_input(INPUT);
    println!("Part 1: {}", simulate(jets.clone(), 2022));
    println!("Part 2: {}", simulate(jets, 1_000_000_000_000));
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash, Deserialize)]
enum Direction {
    #[serde(rename = "<")]
    Left,
    #[serde(rename = ">")]
    Right,
}

impl FromStr for Direction {
    type Err = value::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Self::deserialize(s.into_deserializer())
    }
}

fn parse_input(text: &str) -> Vec<Direction> {
    text.trim()
        .chars()
        .map(|c| Direction::from_str(&c.to_string()).unwrap())
        .collect()
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
enum Piece {
    Dash,
    Plus,
    Corner,
    Line,
    Square,
}

impl Piece {
    // TODO(variant_count): std::mem::variant_count::<Piece>()
    const NUM_SHAPES: usize = 5;

    fn generator() -> impl Iterator<Item = Self> {
        use Piece::*;
        [Dash, Plus, Corner, Line, Square].into_iter().cycle()
    }

    fn new_rows(&self) -> Vec<Row> {
        #[rustfmt::skip]
        let rows: Vec<&str> = match self {
            Piece::Dash => vec![
                "..####.",
            ],
            Piece::Plus => vec![
                "...#...",
                "..###..",
                "...#...",
            ],
            Piece::Corner => vec![
                "....#..",
                "....#..",
                "..###..",
            ],
            Piece::Line => vec![
                "..#....",
                "..#....",
                "..#....",
                "..#....",
            ],
            Piece::Square => vec![
                "..##...",
                "..##...",
            ],
        };

        rows.iter()
            .rev() // Bottom-up!
            .map(|s| Row::parse(s))
            .collect()
    }
}

// Stored bottom-up!
#[derive(Debug, Clone)]
struct Block(Vec<Row>);

impl Block {
    fn new(p: Piece) -> Self {
        Self(p.new_rows())
    }

    fn push(&self, dir: Direction) -> Option<Self> {
        let rows = Row::push_all(&self.0, dir);
        rows.map(Self)
    }
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct Row([bool; 7]);

impl Row {
    const EMPTY: Self = Self([false; 7]);

    fn parse(s: &str) -> Self {
        let bools: Vec<bool> = s.chars().map(|c| c == '#').collect();
        bools.try_into().unwrap()
    }

    fn is_empty(&self) -> bool {
        self.0.iter().all(|&v| !v)
    }

    fn is_full(&self) -> bool {
        self.0.iter().all(|&v| v)
    }

    fn intersects(&self, other: &Self) -> bool {
        self.0.iter().zip(other.0.iter()).any(|(&t, &p)| t && p)
    }

    fn merge(&self, other: &Self) -> Self {
        let pairs = self.0.iter().zip(other.0.iter());
        let a: Vec<bool> = pairs
            .map(|(&t, &p)| {
                if t && p {
                    panic!("merging piece that collides with tower");
                }
                t || p
            })
            .collect();
        a.into()
    }

    fn push(&self, dir: Direction) -> Result<Self, ()> {
        match dir {
            Direction::Left => {
                // Touching left edge, can't move.
                if self.0[0] {
                    Err(())
                } else {
                    let mut a = self.0;
                    a.rotate_left(1);
                    Ok(Self(a))
                }
            }
            Direction::Right => {
                // Touching right edge, can't move.
                if self.0[6] {
                    Err(())
                } else {
                    let mut a = self.0;
                    a.rotate_right(1);
                    Ok(Self(a))
                }
            }
        }
    }

    fn push_all(rs: &[Self], dir: Direction) -> Option<Vec<Self>> {
        let pushed: Result<Vec<Self>, ()> = rs.iter().cloned().map(|r| r.push(dir)).collect();
        pushed.ok()
    }
}

impl From<Vec<bool>> for Row {
    fn from(v: Vec<bool>) -> Self {
        Self(v.try_into().unwrap())
    }
}

#[derive(Debug, Clone)]
struct Tower {
    grid: Vec<Row>,
    rows_removed: usize,
    pieces: usize,
}

impl Tower {
    fn new() -> Self {
        Self {
            grid: vec![],
            rows_removed: 0,
            pieces: 0,
        }
    }

    fn height(&self) -> usize {
        self.grid.len() + self.rows_removed
    }

    fn spawn(&mut self, piece: Piece, jets: &mut impl Iterator<Item = Direction>) -> usize {
        let mut block = Block::new(piece);
        let mut y = self.grid.len() + 3;

        self.grid.extend([Row::EMPTY; 4]);

        let mut dj = 0;
        loop {
            // Push!
            let dir = jets.next().unwrap();
            dj += 1;
            if let Some(new_block) = block.push(dir) {
                if self.can_place(y, &new_block) {
                    block = new_block;
                }
            };

            // Fall!
            let Some(new_y) = y.checked_sub(1) else {
                break;
            };
            if self.can_place(new_y, &block) {
                y = new_y;
            } else {
                break;
            }
        }

        self.place_at(y, block);
        self.clean();

        self.pieces += 1;
        dj
    }

    fn clean(&mut self) {
        // Garbage-collect empty rows.
        let saved = self.grid.len();
        let empty = self.grid.iter().rev().take_while(|r| r.is_empty()).count();
        self.grid.truncate(saved - empty);
    }

    fn top(&self) -> Vec<Row> {
        self.grid
            .iter()
            .cloned()
            .rev()
            .take_while(|r| !r.is_full())
            .collect()
    }

    fn can_place(&self, y: usize, block: &Block) -> bool {
        let mut window = self.grid[y..].iter().zip(&block.0);
        !window.any(|(tower, piece)| tower.intersects(piece))
    }

    fn place_at(&mut self, y: usize, block: Block) {
        for (yy, p) in (y..).zip(block.0) {
            let tower = self.grid[yy];
            self.grid[yy] = tower.merge(&p);
        }
    }
}

fn simulate(jets: Vec<Direction>, rock_count: usize) -> usize {
    let (base_tower, loop_state) = find_loop(jets.clone());
    let template = run_loop(&base_tower, jets.clone(), &loop_state);

    let mut pieces_used = base_tower.pieces;
    let mut jet_idx = loop_state.jet;
    let mut tower_height = base_tower.height();

    while pieces_used + template.pieces < rock_count {
        pieces_used += template.pieces;
        tower_height += template.height;
        jet_idx += template.jets % jets.len();
    }

    let remaining_rocks = rock_count - pieces_used;
    let leftover_pieces = Piece::generator()
        .skip(pieces_used % Piece::NUM_SHAPES)
        .take(remaining_rocks);
    let leftover_jets = jets.iter().cloned().skip(jet_idx);

    let leftover_height = run(&base_tower, leftover_pieces, leftover_jets);

    tower_height + leftover_height
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct State {
    piece: Piece,
    jet: usize,
    top: Vec<Row>,
}

fn find_loop(jets: Vec<Direction>) -> (Tower, State) {
    let mut pieces = Piece::generator();
    let mut jets_iter = jets.iter().cloned().cycle();
    let mut tower = Tower::new();

    let mut states: HashSet<State> = HashSet::new();
    let mut jets_used = 0;

    let mut loop_start: Option<(State, usize)> = None;

    for piece in &mut pieces {
        let state = State {
            piece,
            jet: jets_used % jets.len(),
            top: tower.top(),
        };
        let looped = !states.insert(state.clone());
        if looped {
            loop_start = Some((state, tower.height()));
            break;
        }

        let dj = tower.spawn(piece, &mut jets_iter);
        jets_used += dj;
    }

    (tower, loop_start.unwrap().0)
}

#[derive(Debug, Copy, Clone)]
struct LoopInfo {
    pieces: usize,
    jets: usize,
    height: usize,
}

fn run_loop(base_tower: &Tower, jets: Vec<Direction>, loop_start: &State) -> LoopInfo {
    let mut tower = base_tower.clone();

    let pieces = Piece::generator().skip_while(|&p| p != loop_start.piece);

    let num_jets = jets.len();
    let mut jets = jets.iter().cloned().cycle().skip(loop_start.jet); // off-by-one?
    let mut jets_used = loop_start.jet;
    let mut seen = 0;

    for (pieces_used, piece) in pieces.enumerate() {
        let state = State {
            piece,
            jet: jets_used % num_jets,
            top: tower.top(),
        };
        seen += i32::from(state == *loop_start);
        if seen == 2 {
            return LoopInfo {
                pieces: pieces_used,
                jets: jets_used - loop_start.jet,
                height: tower.height() - base_tower.height(),
            };
        }

        let dj = tower.spawn(piece, &mut jets);
        jets_used += dj;
    }

    unreachable!();
}

fn run(
    base_tower: &Tower,
    pieces: impl Iterator<Item = Piece>,
    mut jets: impl Iterator<Item = Direction>,
) -> usize {
    let base_height = base_tower.height();
    let mut tower: Tower = base_tower.clone();
    for piece in pieces {
        tower.spawn(piece, &mut jets);
    }
    tower.height() - base_height
}

impl Tower {
    #[allow(dead_code)]
    fn render(&self) {
        // TODO(int_log): self.0.checked_log10().unwrap_or(0) + 1
        let width = format!("{}", self.height()).chars().count();

        for (i, row) in self.grid.iter().enumerate().rev() {
            println!("{: >width$} {}", i + self.rows_removed, row);
        }
        println!("  -------");
    }
}

impl Display for Row {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        for occupied in self.0 {
            let c = if occupied { '#' } else { '.' };
            write!(f, "{}", c)?
        }
        Ok(())
    }
}
