use std::{iter::Peekable, str::Chars};

const INPUT: &str = include_str!("../../input/day22.txt");

fn main() {
    let (board, moves) = parse(INPUT);

    println!("{}", part1(board.clone(), moves.clone()));
    println!("{}", part2(board, moves));
}

fn parse(input: &str) -> (Board, Vec<Move>) {
    let mut blocks = aoc::blocks(input);

    let board = Board::parse(blocks.next().unwrap());
    let moves = Move::parse_all(blocks.next().unwrap().trim());

    assert!(blocks.next().is_none());

    (board, moves)
}

#[derive(Debug, Clone)]
struct Board {
    rows: Vec<Range>,
    cols: Vec<Range>,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum Tile {
    Open,
    Wall,
}

#[derive(Debug, Clone)]
struct Range {
    start: usize,
    tiles: Vec<Tile>,
}

impl Range {
    fn start(&self) -> usize {
        self.start
    }

    fn end(&self) -> usize {
        self.start + self.tiles.len() - 1
    }

    fn at(&self, c: usize) -> Option<Tile> {
        if self.start() <= c && c <= self.end() {
            return Some(self.tiles[c - self.start]);
        }
        None
    }
}

impl Board {
    fn parse(text: &str) -> Self {
        let rows = Self::parse_rows(text);
        let cols = Self::parse_cols(&rows);

        let row_max = rows.len() - 1;
        let col_max = cols.len() - 1;

        let board = Self { rows, cols };
        board.check(row_max, col_max);
        board
    }

    fn parse_rows(text: &str) -> Vec<Range> {
        let lines: Vec<&str> = text.lines().collect();

        let mut rows = vec![];

        let mut col_max = 0;

        for line in lines.iter() {
            let mut start = 0usize;
            let mut tiles = vec![];
            for fill in line.chars() {
                match fill {
                    ' ' => start += 1,
                    '.' => tiles.push(Tile::Open),
                    '#' => tiles.push(Tile::Wall),
                    other => panic!("{:?}", other),
                }
            }

            col_max = col_max.max(start + tiles.len());

            rows.push(Range { start, tiles });
        }

        rows
    }

    fn parse_cols(rows: &[Range]) -> Vec<Range> {
        let col_max = rows.iter().map(|r| r.end()).max().unwrap();

        let mut cols = vec![];

        for c in 0..=col_max {
            let mut start = 0;
            for (r, row) in rows.iter().enumerate() {
                if row.at(c).is_some() {
                    start = r;
                    break;
                }
            }

            let mut tiles = vec![];
            for row in &rows[start..] {
                let Some(tile) = row.at(c) else {
                        break;
                    };

                tiles.push(tile);
            }

            cols.push(Range { start, tiles })
        }

        cols
    }

    fn check(&self, row_max: usize, col_max: usize) {
        for r in 0..=row_max {
            for c in 0..=col_max {
                assert_eq!(self.rows[r].at(c), self.cols[c].at(r), "{} {}", r, c);
            }
        }
    }
}

#[derive(Debug, Copy, Clone)]
enum Move {
    Forward(u64),
    Left,
    Right,
}

impl Move {
    fn parse_all(line: &str) -> Vec<Self> {
        let mut chars = line.chars().peekable();
        let mut moves = vec![];

        let mut mv = chars.peek().unwrap().is_ascii_digit();
        while chars.peek().is_some() {
            if mv {
                moves.push(Self::parse_walk(&mut chars));
            } else {
                moves.push(Self::parse_turn(&mut chars));
            }
            mv = !mv;
        }
        assert!(chars.peek().is_none());
        moves
    }

    fn parse_walk(chars: &mut Peekable<Chars>) -> Self {
        let mut n = 0;
        loop {
            let Some(c) = chars.peek() else {
                break;
            };
            if !c.is_ascii_digit() {
                break;
            }

            let c = chars.next().unwrap();

            n *= 10;
            n += (c as u64) - ('0' as u64);
        }
        Move::Forward(n)
    }

    fn parse_turn(chars: &mut Peekable<Chars>) -> Self {
        match chars.next().unwrap() {
            'L' => Move::Left,
            'R' => Move::Right,
            other => panic!("{:?}", other),
        }
    }
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum Heading {
    North,
    East,
    South,
    West,
}

impl Heading {
    fn turn_left(&self) -> Self {
        use Heading::*;
        match self {
            North => West,
            East => North,
            South => East,
            West => South,
        }
    }

    fn turn_right(&self) -> Self {
        use Heading::*;
        match self {
            North => East,
            East => South,
            South => West,
            West => North,
        }
    }

    fn flip(&self) -> Self {
        use Heading::*;
        match self {
            North => South,
            East => West,
            South => North,
            West => East,
        }
    }
}

fn part1(board: Board, moves: Vec<Move>) -> u64 {
    let mut r = 0;
    let mut c = board.rows[r].start;
    let mut h = Heading::East;

    for mv in moves {
        match mv {
            Move::Left => h = h.turn_left(),
            Move::Right => h = h.turn_right(),
            Move::Forward(steps) => (r, c) = board.walk(r, c, h, steps),
        }
    }

    score(r, c, h)
}

fn score(r: usize, c: usize, h: Heading) -> u64 {
    // 1 indexing
    let r: u64 = (r + 1).try_into().unwrap();
    let c: u64 = (c + 1).try_into().unwrap();

    let h = match h {
        Heading::East => 0,
        Heading::South => 1,
        Heading::West => 2,
        Heading::North => 3,
    };

    1000 * r + 4 * c + h
}

impl Board {
    fn walk(&self, r: usize, c: usize, h: Heading, distance: u64) -> (usize, usize) {
        let d: i64 = distance.try_into().unwrap();
        match h {
            Heading::North => self.walk_vertical(r, c, -d),
            Heading::South => self.walk_vertical(r, c, d),

            Heading::East => self.walk_horizontal(r, c, d),
            Heading::West => self.walk_horizontal(r, c, -d),
        }
    }

    fn walk_horizontal(&self, r: usize, c: usize, dc: i64) -> (usize, usize) {
        let c = self.rows[r].walk(c, dc);
        (r, c)
    }

    fn walk_vertical(&self, r: usize, c: usize, dr: i64) -> (usize, usize) {
        let r = self.cols[c].walk(r, dr);
        (r, c)
    }
}

impl Range {
    fn walk(&self, offset: usize, delta: i64) -> usize {
        let to_walk: usize = delta.abs().try_into().unwrap();

        let dest = self
            .walkway(offset, delta < 0)
            .iter()
            .cloned()
            .cycle()
            .take(to_walk + 1) // Consume the start tile
            .take_while(|&(_i, t)| t == Tile::Open)
            .last();

        match dest {
            Some((i, _tile)) => i,
            None => offset, // Didn't move
        }
    }

    fn walkway(&self, offset: usize, reverse: bool) -> Vec<(usize, Tile)> {
        let mut walkway: Vec<(usize, Tile)> = self
            .tiles
            .iter()
            .cloned()
            .enumerate()
            .map(|(i, t)| (i + self.start, t))
            .collect();

        if reverse {
            walkway.reverse();
            walkway.drain(0..(self.end() - offset));
        } else {
            // Walkway starts at current position and _does not_ wrap.
            walkway.drain(0..(offset - self.start));
        }
        assert_eq!(walkway[0], (offset, Tile::Open));

        walkway
    }
}

fn part2(board: Board, moves: Vec<Move>) -> u64 {
    let mut r = 0;
    let mut c = board.rows[r].start;
    let mut h = Heading::East;

    for mv in moves {
        match mv {
            Move::Left => h = h.turn_left(),
            Move::Right => h = h.turn_right(),
            Move::Forward(mut steps) => {
                'walk: while steps > 0 {
                    // Finish current face
                    let walkway = board.walkway(r, c, h);

                    let mut ww = walkway.iter();
                    // Consume the current tile.
                    assert_eq!(ww.next(), Some(&(r, c, Tile::Open)));

                    'face: while steps > 0 {
                        let Some(&(rr, cc, t)) = ww.next() else {
                            break 'face;
                        };

                        if t == Tile::Wall {
                            break 'walk;
                        }

                        (r, c) = (rr, cc);
                        steps -= 1;
                    }

                    // Teleport to a new face
                    if steps > 0 {
                        let (rr, cc, hh, t) = board.faceroll(r, c, h);
                        {
                            let (rrr, ccc, hhh, _) = board.faceroll(rr, cc, hh.flip());
                            assert_eq!((r, c, h), (rrr, ccc, hhh.flip()));
                        }

                        if t == Tile::Wall {
                            break 'walk;
                        }

                        (r, c, h) = (rr, cc, hh);
                        steps -= 1;
                    }
                }
            }
        }
    }

    score(r, c, h)
}

impl Board {
    fn walkway(&self, r: usize, c: usize, h: Heading) -> Vec<(usize, usize, Tile)> {
        use Heading::*;

        match h {
            North => self.cols[c]
                .walkway(r, true)
                .iter()
                .map(|&(r, t)| (r, c, t))
                .collect(),
            South => self.cols[c]
                .walkway(r, false)
                .iter()
                .map(|&(r, t)| (r, c, t))
                .collect(),

            East => self.rows[r]
                .walkway(c, false)
                .iter()
                .map(|&(c, t)| (r, c, t))
                .collect(),
            West => self.rows[r]
                .walkway(c, true)
                .iter()
                .map(|&(c, t)| (r, c, t))
                .collect(),
        }
    }

    fn faceroll(&self, r: usize, c: usize, h: Heading) -> (usize, usize, Heading, Tile) {
        use Heading::*;

        // In order of appearance...
        let (rr, cc, hh) = match (r, c, h) {
            (0..=49, 149, East) => (149 - r, 99, West),     // B -> D
            (0..=49, 50, West) => (149 - r, 0, East),       // A -> E
            (100..=149, 0, West) => (149 - r, 50, East),    // E -> A
            (50..=99, 50, West) => (100, r - 50, South),    // C -> E
            (100, 0..=49, North) => (c + 50, 50, East),     // E -> C
            (0, 50..=99, North) => (c + 100, 0, East),      // A -> F
            (199, 0..=49, South) => (0, c + 100, South),    // F -> B
            (150..=199, 49, East) => (149, r - 100, North), // F -> D

            (0, 100..=149, North) => (199, c - 100, North), // B -> F
            (149, 50..=99, South) => (c + 100, 49, West),   // D -> F
            (150..=199, 0, West) => (0, r - 100, South),    // F -> A
            (50..=99, 99, East) => (49, r + 50, North),     // C -> B
            (100..=149, 99, East) => (149 - r, 149, West),  // D -> B
            (49, 100..=149, South) => (c - 50, 99, West),   // B -> C
            other => todo!("{:?}", other),
        };

        let t = self.rows[rr].at(cc).unwrap();
        (rr, cc, hh, t)
    }
}
