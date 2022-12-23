use std::collections::{HashMap, VecDeque};

const INPUT: &str = include_str!("../../input/day21.txt");

fn main() {
    let monkeys = parse(INPUT);
    println!("{:?}", part1(monkeys.clone()));
}

fn parse(input: &str) -> HashMap<Name, Expr> {
    input
        .lines()
        .map(|line| {
            let words: Vec<&str> = line.split(": ").collect();
            let name = words[0].to_string();
            let expr = Expr::parse(words[1]);

            (name, expr)
        })
        .collect()
}

type Name = String;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
enum Expr {
    Const(u64),
    Monkey(Name),
    Add(Box<Expr>, Box<Expr>),
    Sub(Box<Expr>, Box<Expr>),
    Mul(Box<Expr>, Box<Expr>),
    Div(Box<Expr>, Box<Expr>),
}

impl Expr {
    fn parse(s: &str) -> Self {
        let w: Vec<&str> = s.split(' ').collect();

        if w.len() == 1 {
            Expr::parse_atom(w[0])
        } else {
            Expr::parse_binary(w)
        }
    }

    fn parse_atom(s: &str) -> Self {
        match s.parse::<u64>() {
            Ok(u) => Expr::Const(u),
            Err(_) => Expr::Monkey(s.to_string()),
        }
    }

    fn parse_binary(w: Vec<&str>) -> Self {
        assert_eq!(w.len(), 3);

        let l = Self::parse_atom(w[0]);
        let r = Self::parse_atom(w[2]);

        match w[1] {
            "+" => Expr::Add(Box::new(l), Box::new(r)),
            "-" => Expr::Sub(Box::new(l), Box::new(r)),
            "*" => Expr::Mul(Box::new(l), Box::new(r)),
            "/" => Expr::Div(Box::new(l), Box::new(r)),
            other => panic!("{}", other),
        }
    }
}

fn part1(monkeys: HashMap<Name, Expr>) -> u64 {
    let mut ev = Evaluator::new(monkeys);
    ev.eval("root".to_string())
}

impl Expr {
    fn bindings(&self) -> Vec<Name> {
        match self {
            Expr::Const(_) => vec![],
            Expr::Monkey(name) => vec![name.clone()],
            Expr::Add(l, r) => [l.bindings(), r.bindings()].concat(),
            Expr::Sub(l, r) => [l.bindings(), r.bindings()].concat(),
            Expr::Mul(l, r) => [l.bindings(), r.bindings()].concat(),
            Expr::Div(l, r) => [l.bindings(), r.bindings()].concat(),
        }
    }

    fn value(&self, memo: &HashMap<Name, u64>) -> u64 {
        match self {
            Expr::Const(v) => *v,
            Expr::Monkey(name) => memo[name],
            Expr::Add(l, r) => l.value(memo) + r.value(memo),
            Expr::Sub(l, r) => l.value(memo) - r.value(memo),
            Expr::Mul(l, r) => l.value(memo) * r.value(memo),
            Expr::Div(l, r) => l.value(memo) / r.value(memo),
        }
    }
}

#[derive(Debug, Clone)]
struct Evaluator {
    memo: HashMap<Name, u64>,
    monkeys: HashMap<Name, Expr>,
}

impl Evaluator {
    fn new(monkeys: HashMap<Name, Expr>) -> Self {
        Self {
            memo: Default::default(),
            monkeys,
        }
    }

    fn eval(&mut self, name: Name) -> u64 {
        let mut queue: VecDeque<Name> = Default::default();
        queue.push_front(name.clone());

        let mut needed: VecDeque<Name> = Default::default();

        while let Some(want) = queue.pop_front() {
            if needed.contains(&want) {
                continue;
            }
            needed.push_front(want.clone());

            for name in self.monkeys[&want].bindings() {
                queue.push_front(name.to_string());
            }
        }

        for name in needed {
            let expr = &self.monkeys[&name];
            let v = expr.value(&self.memo);
            self.memo.insert(name, v);
        }

        self.memo[&name]
    }
}
