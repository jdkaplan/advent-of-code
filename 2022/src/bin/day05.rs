use regex::Regex;

const INPUT: &str = include_str!("../../input/day05.txt");

fn main() {
    println!("{}", part1(INPUT));
    println!("{}", part2(INPUT));
}

type Crate = String;

type Stack = Vec<Crate>;

#[derive(Debug, Clone)]
struct Ship {
    stacks: Vec<Stack>,
}

impl Ship {
    fn parse(input: &str) -> Self {
        let lines: Vec<&str> = input.trim().split('\n').rev().collect();

        let mut ship = Ship {
            stacks: (0..=8).map(|_| Vec::new()).collect(),
        };

        for line in &lines[1..] {
            for stk in 0..=8 {
                let i = 4 * stk + 1;
                let contents = match line.get(i..i + 1) {
                    None => continue,
                    Some(" ") => continue,
                    Some(contents) => contents,
                };
                ship.stacks[stk].push(contents.to_string());
            }
        }

        ship
    }

    fn do_move_1(&mut self, m: Move) {
        for _ in 0..(m.count) {
            let item = self.stacks[m.from].pop().expect("must have item");
            self.stacks[m.to].push(item);
        }
    }

    fn do_move_2(&mut self, m: Move) {
        let src = &mut self.stacks[m.from];
        let items = src.split_off(src.len() - m.count);
        self.stacks[m.to].extend(items.to_vec());
    }

    fn tops(&self) -> String {
        let mut s = String::new();
        for stk in &self.stacks {
            s += stk.last().unwrap();
        }
        s
    }
}

#[derive(Debug, Copy, Clone)]
struct Move {
    count: usize,
    from: usize,
    to: usize,
}

impl Move {
    fn parse(line: &str) -> Self {
        let re = Regex::new(r"^move (\d+) from (\d+) to (\d+)$").unwrap();
        let caps = re.captures(line).unwrap();

        Self {
            count: caps[1].parse().unwrap(),
            from: caps[2].parse::<usize>().unwrap() - 1, // zero-index
            to: caps[3].parse::<usize>().unwrap() - 1,   // zero-index
        }
    }
}

fn part1(input: &str) -> String {
    let sections: Vec<&str> = input.split("\n\n").collect();

    let mut ship = Ship::parse(sections[0]);
    let moves: Vec<Move> = sections[1].trim().split('\n').map(Move::parse).collect();

    for m in moves {
        ship.do_move_1(m);
    }

    ship.tops()
}

fn part2(input: &str) -> String {
    let sections: Vec<&str> = input.split("\n\n").collect();

    let mut ship = Ship::parse(sections[0]);
    let moves: Vec<Move> = sections[1].trim().split('\n').map(Move::parse).collect();

    for m in moves {
        ship.do_move_2(m);
    }

    ship.tops()
}
