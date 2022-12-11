use std::collections::VecDeque;

use regex::Regex;

const INPUT: &str = include_str!("../../input/day11.txt");

fn main() {
    let monkeys: Vec<Monkey> = aoc::blocks(INPUT).map(Monkey::parse).collect();

    println!("Part 1: {}", monkey_business(monkeys.clone(), 20, 3));
    println!("Part 2: {}", monkey_business(monkeys, 10_000, 1));
}

fn monkey_business(mut monkeys: Vec<Monkey>, rounds: usize, confidence: i64) -> usize {
    let yolo_factor: i64 = monkeys.iter().map(|m| m.test.divisor).product();

    for _ in 1..=rounds {
        for m in 0..monkeys.len() {
            let mut monkey = std::mem::take(&mut monkeys[m]);
            let mut items = std::mem::take(&mut monkey.items);

            for mut item in items.drain(0..) {
                monkey.inspections += 1;
                item.worry = monkey.operation.apply(item.worry);

                item.worry /= confidence;
                item.worry %= yolo_factor;

                let dest = monkey.test.apply(item.worry);
                monkeys[dest].items.push_back(item);
            }

            let id = monkey.id;
            monkeys[id] = monkey;
        }
    }

    let mut counts: Vec<usize> = monkeys.iter().map(|m| m.inspections).collect();
    counts.sort();
    counts.iter().rev().take(2).product()
}

#[derive(Debug, Clone, Default)]
struct Monkey {
    id: usize,
    items: VecDeque<Item>,
    operation: Operation,
    test: Test,

    inspections: usize,
}

type Worry = i64;

#[derive(Debug, Copy, Clone, Default)]
struct Item {
    worry: Worry,
}

#[derive(Debug, Copy, Clone, Default)]
struct Operation {
    operator: Operator,
    operand: Operand,
}

#[derive(Debug, Copy, Clone, Default)]
enum Operator {
    #[default]
    Plus,
    Times,
}

#[derive(Debug, Copy, Clone, Default)]
enum Operand {
    Const(i64),
    #[default]
    Old,
}

impl Operation {
    fn parse(line: &str) -> Self {
        assert!(line.starts_with("  Operation: "));

        let re = Regex::new(r"new = old (.) (.+)").unwrap();
        let caps = re.captures(line).unwrap();

        use {Operand::*, Operator::*};

        let operator = match &caps[1] {
            "+" => Plus,
            "*" => Times,
            other => panic!("{}", other),
        };

        let operand = match &caps[2] {
            "old" => Operand::Old,
            i => Const(i.parse().unwrap()),
        };

        Operation { operator, operand }
    }

    fn apply(&self, old: Worry) -> Worry {
        use {Operand::*, Operator::*};

        match (self.operand, self.operator) {
            (Const(n), Plus) => old + n,
            (Old, Plus) => old + old,
            (Const(n), Times) => old * n,
            (Old, Times) => old * old,
        }
    }
}

#[derive(Debug, Copy, Clone, Default)]
struct Test {
    divisor: i64,
    target_true: usize,
    target_false: usize,
}

impl Test {
    fn parse(lines: &[&str]) -> Self {
        let divisor: i64 = {
            let line = lines[0];
            let re = Regex::new(r"^  Test: divisible by (\d+)$").unwrap();
            let caps = re.captures(line).unwrap();
            caps[1].parse().unwrap()
        };

        let target_true: usize = {
            let line = lines[1];
            let re = Regex::new(r"^    If true: throw to monkey (\d+)$").unwrap();
            let caps = re.captures(line).unwrap();
            caps[1].parse().unwrap()
        };

        let target_false: usize = {
            let line = lines[2];
            let re = Regex::new(r"^    If false: throw to monkey (\d+)$").unwrap();
            let caps = re.captures(line).unwrap();
            caps[1].parse().unwrap()
        };

        Self {
            divisor,
            target_true,
            target_false,
        }
    }

    fn apply(&self, worry: Worry) -> usize {
        if worry % self.divisor == 0 {
            self.target_true
        } else {
            self.target_false
        }
    }
}

impl Monkey {
    fn parse(s: &str) -> Self {
        let lines: Vec<&str> = aoc::lines(s).collect();

        let id: usize = {
            let line = lines[0];

            let re = Regex::new(r"^Monkey (\d+):").unwrap();
            let caps = re.captures(line).unwrap();

            caps[1].parse().unwrap()
        };

        let items: VecDeque<Item> = {
            let line = lines[1];
            assert!(line.starts_with("  Starting items: "));

            let re = Regex::new(r"(\d+)").unwrap();
            re.captures_iter(line)
                .map(|cap| {
                    let worry = cap[1].parse().unwrap();
                    Item { worry }
                })
                .collect()
        };

        let operation = Operation::parse(lines[2]);
        let test = Test::parse(&lines[3..]);

        Self {
            id,
            items,
            operation,
            test,

            inspections: 0,
        }
    }
}
