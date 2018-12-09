use std::collections::HashMap;
use std::collections::HashSet;
use std::fmt;

const INPUT: &str = include_str!("input/day5.txt");
// const INPUT: &str = "dabAcCaCBAcCcaDA";

#[derive(Debug, PartialEq, Eq, Clone)]
enum Polarity {
    Upper,
    Lower,
}

#[derive(Debug, Clone)]
struct Unit {
    name: String,
    polarity: Polarity,
}

type Polymer = Vec<Unit>;
impl fmt::Display for Unit {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let c = match self.polarity {
            Polarity::Upper => self.name.to_uppercase(),
            Polarity::Lower => self.name.to_lowercase(),
        };
        write!(f, "{}", c)
    }
}

fn parse_input(s: String) -> Polymer {
    let mut polymer = Vec::new();
    for c in s.chars() {
        polymer.push(Unit {
            name: c.to_lowercase().to_string(),
            polarity: if c.is_lowercase() {
                Polarity::Lower
            } else {
                Polarity::Upper
            },
        });
    }
    polymer
}

fn can_cancel(u1: &Unit, u2: &Unit) -> bool {
    u1.name == u2.name && u1.polarity != u2.polarity
}

// TODO: optimize
fn reduce(p: &mut Polymer) -> &Polymer {
    let mut i = 0;
    while i + 1 < p.len() {
        if can_cancel(&p[i], &p[i + 1]) {
            p.remove(i + 1);
            p.remove(i);
            return p;
        }
        i += 1;
    }
    p
}

fn reduce_fully(p: &mut Polymer) -> &Polymer {
    let mut old_len = p.len();
    loop {
        reduce(p);
        let new_len = p.len();
        if new_len == old_len {
            break;
        }
        old_len = new_len;
    }
    p
}

pub fn part1() -> usize {
    let mut polymer = parse_input(INPUT.to_string());
    reduce_fully(&mut polymer);
    polymer.len()
}

fn unit_types(p: Polymer) -> HashSet<String> {
    let mut types = HashSet::new();
    for u in p {
        types.insert(u.name);
    }
    types
}

fn remove_all(p: Polymer, t: String) -> Polymer {
    p.into_iter().filter(|u| u.name != t).collect()
}

pub fn part2() -> &'static str {
    let original = parse_input(INPUT.to_string());
    let types = unit_types(original.clone());
    let mut lengths = HashMap::new();
    for t in types {
        let mut cleaned = remove_all(original.clone(), t.clone());
        reduce_fully(&mut cleaned);
        lengths.insert(t, cleaned.len());
    }
    "TODO"
}
