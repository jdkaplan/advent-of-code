use std::{convert::TryInto, fmt::Display, str::FromStr};

use serde::{
    de::{value, IntoDeserializer},
    Deserialize,
};

// const INPUT: (&str, usize) = (include_str!("../../input/day17-ex.txt"), 10);
const INPUT: (&str, usize) = (include_str!("../../input/day17.txt"), 2022);

fn main() {
    let (text, rock_count) = INPUT;
    let jets = parse_input(text);
    println!("{}", part1(jets, rock_count));
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
                ".......",
                "..##...",
                "..##...",
            ],
        };

        rows.iter()
            .rev() // Bottom-up!
            .map(|row| {
                let bools: Vec<bool> = row.chars().map(|c| c == '#').collect();
                TryInto::<Row>::try_into(bools).unwrap()
            })
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

#[derive(Debug, Copy, Clone)]
struct Row([bool; 7]);

impl Row {
    const EMPTY: Self = Self([false; 7]);

    fn is_empty(&self) -> bool {
        self.0.iter().all(|&v| !v)
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
}

impl Tower {
    fn new() -> Self {
        Self { grid: vec![] }
    }

    fn height(&self) -> usize {
        let empty_rows = self.grid.iter().rev().take_while(|r| r.is_empty()).count();
        self.grid.len() - empty_rows
    }

    fn spawn(&mut self, piece: Piece, jets: &mut impl Iterator<Item = Direction>) {
        self.grid.extend([Row::EMPTY; 4]);

        let mut block = Block::new(piece);
        let mut y = self.height() + 3;

        loop {
            // Push!
            let dir = jets.next().unwrap();
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

        self.grid.truncate(self.height());
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

fn part1(jets: Vec<Direction>, rock_count: usize) -> usize {
    let pieces = Piece::generator().take(rock_count);
    let mut jets = jets.into_iter().cycle();

    let mut tower = Tower::new();

    for piece in pieces {
        tower.spawn(piece, &mut jets);
        // tower.render();
    }

    tower.height()
}

impl Tower {
    fn render(&self) {
        for (i, row) in self.grid.iter().enumerate().rev() {
            println!("{} {}", i, row);
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
