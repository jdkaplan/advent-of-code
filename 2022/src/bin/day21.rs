use std::collections::{HashMap, VecDeque};

const INPUT: &str = include_str!("../../input/day21.txt");

fn main() {
    let monkeys = parse(INPUT);
    println!("{:?}", part1(monkeys.clone()));
    println!("{:?}", part2(monkeys));
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

fn part2(mut monkeys: HashMap<Name, Expr>) -> u64 {
    let human: Name = "humn".into();

    monkeys.remove(&human);

    let dependents: usize = monkeys
        .iter()
        .filter_map(|(_name, expr)| expr.bindings().iter().position(|b| b == "humn"))
        .count();
    assert_eq!(dependents, 1);

    let names = monkeys["root"].bindings();
    assert_eq!(names.len(), 2);

    let mut a = Tree::build(Expr::Monkey(names[0].clone()), &monkeys);
    let mut b = Tree::build(Expr::Monkey(names[1].clone()), &monkeys);

    let leaf = Tree::Monkey(human.clone());
    while a != leaf {
        (a, b) = Tree::reroot(a, b, &human);
    }

    b.value()
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum Tree {
    Const(u64),
    Monkey(Name),
    BinOp(Op, Box<Tree>, Box<Tree>),
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
enum Op {
    Add,
    Sub,
    Mul,
    Div,
}

impl Tree {
    fn build(expr: Expr, monkeys: &HashMap<Name, Expr>) -> Self {
        match expr {
            Expr::Const(v) => Tree::Const(v),
            Expr::Monkey(m) => {
                if let Some(e) = monkeys.get(&m) {
                    Tree::build(e.clone(), monkeys)
                } else {
                    Tree::Monkey(m)
                }
            }
            Expr::Add(l, r) => Tree::BinOp(
                Op::Add,
                Tree::build(*l, monkeys).into(),
                Tree::build(*r, monkeys).into(),
            ),
            Expr::Sub(l, r) => Tree::BinOp(
                Op::Sub,
                Tree::build(*l, monkeys).into(),
                Tree::build(*r, monkeys).into(),
            ),
            Expr::Mul(l, r) => Tree::BinOp(
                Op::Mul,
                Tree::build(*l, monkeys).into(),
                Tree::build(*r, monkeys).into(),
            ),
            Expr::Div(l, r) => Tree::BinOp(
                Op::Div,
                Tree::build(*l, monkeys).into(),
                Tree::build(*r, monkeys).into(),
            ),
        }
    }

    fn contains(&self, name: &Name) -> bool {
        match self {
            Tree::Const(_) => false,
            Tree::Monkey(m) => m == name,
            Tree::BinOp(_, l, r) => l.contains(name) || r.contains(name),
        }
    }

    fn binary(op: Op, l: Self, r: Self) -> Self {
        Tree::BinOp(op, Box::new(l), Box::new(r))
    }

    fn reroot(a: Self, b: Self, name: &Name) -> (Self, Self) {
        assert!(a.contains(name));

        match a {
            Tree::Const(_) => todo!(),
            Tree::Monkey(_) => todo!(),
            Tree::BinOp(op, l, r) => {
                let (aa, bb) = if l.contains(name) {
                    // L op r == b
                    match op {
                        // L + r == b
                        // L == b - r
                        Op::Add => (l, Tree::binary(Op::Sub, b, *r)),
                        // L - r == b
                        // L == b + r
                        Op::Sub => (l, Tree::binary(Op::Add, b, *r)),
                        // L * r == b
                        // L == b / r
                        Op::Mul => (l, Tree::binary(Op::Div, b, *r)),
                        // L / r == b
                        // L == b * r
                        Op::Div => (l, Tree::binary(Op::Mul, b, *r)),
                    }
                } else if r.contains(name) {
                    // l op R == b
                    match op {
                        // l + R == b
                        // R == b - l
                        Op::Add => (r, Tree::binary(Op::Sub, b, *l)),
                        // l - R == b
                        // R == l - b
                        Op::Sub => (r, Tree::binary(Op::Sub, *l, b)),
                        // l * R == b
                        // R == b / l
                        Op::Mul => (r, Tree::binary(Op::Div, b, *l)),
                        // l / R == b
                        // R == l / b
                        Op::Div => (r, Tree::binary(Op::Div, *l, b)),
                    }
                } else {
                    todo!()
                };
                (*aa, bb)
            }
        }
    }

    fn value(&self) -> u64 {
        match self {
            Tree::Const(v) => *v,
            Tree::Monkey(_) => todo!(),
            Tree::BinOp(op, l, r) => match op {
                Op::Add => l.value() + r.value(),
                Op::Sub => l.value() - r.value(),
                Op::Mul => l.value() * r.value(),
                Op::Div => l.value() / r.value(),
            },
        }
    }
}
