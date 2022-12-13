use std::{cmp::Ordering, fmt::Display, iter::Peekable, str::Chars};

const INPUT: &str = include_str!("../../input/day13.txt");

fn main() {
    let packets = parse(INPUT);

    println!("{:?}", part1(&packets));
    println!("{:?}", part2(&packets));
}

fn part1(packets: &[Packet]) -> usize {
    packets
        .iter()
        .enumerate()
        .filter_map(|(i, packet)| {
            if packet.left < packet.right {
                Some(i + 1)
            } else {
                None
            }
        })
        .sum()
}

fn part2(packets: &[Packet]) -> usize {
    let p2 = Data::parse("[[2]]");
    let p6 = Data::parse("[[6]]");

    let mut packets: Vec<Data> = packets
        .iter()
        .flat_map(|p| vec![p.left.clone(), p.right.clone()])
        .collect();

    packets.sort();

    let mut i2 = 1; // 1-indexing
    let mut i6 = 2; // 1-indexing + p2 placeholder

    for p in packets {
        if p < p2 {
            i2 += 1;
        }
        if p < p6 {
            i6 += 1;
        }
    }

    i2 * i6
}

fn parse(input: &str) -> Vec<Packet> {
    aoc::blocks(input)
        .map(|block| {
            let lines: Vec<&str> = aoc::lines(block).collect();
            let left = Data::parse(lines[0]);
            let right = Data::parse(lines[1]);

            Packet { left, right }
        })
        .collect()
}

#[derive(Debug, Clone)]
struct Packet {
    left: Data,
    right: Data,
}

#[derive(Debug, Clone)]
enum Data {
    Value(u32),
    List(Vec<Data>),
}

impl Data {
    fn parse(line: &str) -> Self {
        let mut chars = line.chars().peekable();
        let list = Data::parse_list(&mut chars);
        assert!(chars.peek().is_none());
        list
    }

    fn parse_num(chars: &mut Peekable<Chars>) -> Self {
        let mut digits = String::new();
        while let Some(c) = chars.peek() {
            if c.is_ascii_digit() {
                digits += &chars.next().unwrap().to_string();
            } else {
                break;
            }
        }

        Data::Value(digits.parse().unwrap())
    }

    fn parse_list(chars: &mut Peekable<Chars>) -> Self {
        assert!(chars.next() == Some('['));

        let mut list = vec![];
        while let Some(c) = chars.peek() {
            let val = match c {
                ']' => {
                    chars.next();
                    break;
                }
                '[' => Self::parse_list(chars),
                ',' => {
                    chars.next();
                    continue;
                }
                _ => Self::parse_num(chars),
            };
            list.push(val);
        }

        Data::List(list)
    }
}

impl Data {
    fn lift(&self) -> Self {
        match self {
            Data::List(_) => self.clone(),
            Data::Value(_) => Data::List(vec![self.clone()]),
        }
    }

    fn zip_cmp(l: &[Data], r: &[Data]) -> Ordering {
        let mut ll = l.iter();
        let mut rr = r.iter();

        loop {
            match (ll.next(), rr.next()) {
                (None, None) => return Ordering::Equal,
                (None, Some(_)) => return Ordering::Less,
                (Some(_), None) => return Ordering::Greater,
                (Some(lll), Some(rrr)) => {
                    let d = lll.cmp(rrr);
                    if d != Ordering::Equal {
                        return d;
                    }
                }
            }
        }
    }
}

impl PartialEq for Data {
    fn eq(&self, other: &Self) -> bool {
        self.cmp(other) == Ordering::Equal
    }
}

impl Eq for Data {}

impl PartialOrd for Data {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Data {
    fn cmp(&self, other: &Self) -> Ordering {
        match (self, other) {
            (Data::Value(l), Data::Value(r)) => l.cmp(r),
            (Data::List(l), Data::List(r)) => Data::zip_cmp(l, r),

            (Data::Value(_), Data::List(_)) => self.lift().cmp(other),
            (Data::List(_), Data::Value(_)) => self.cmp(&other.lift()),
        }
    }
}

impl Display for Data {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Data::Value(v) => write!(f, "{}", v),
            Data::List(l) => {
                let items = l
                    .iter()
                    .map(|v| v.to_string())
                    .collect::<Vec<String>>()
                    .join(",");

                write!(f, "[{}]", items)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test1() {
        // let line = "[[[[2],9,1,[2,2,4,8]],[1,8,8],9,[7,2,[7,0,1],0,[10,9,10,3]]]]";
        // let line = "[[[2],9,1,[2,2,4,8]],[1,8,8],9,[7,2,[7,0,1],0,[10,9,10,3]]]";
        // let line = "[[2],9,1,[2,2,4,8]],[1,8,8],9,[7,2,[7,0,1],0,[10,9,10,3]]";
        // let line = "[[2],9,1,[2,2,4,8]]";
        let line = "[[2],9]";
        let data = Data::parse(line);

        assert_eq!(data.to_string(), line);

        use Data::{List, Value};

        assert_eq!(data, List(vec![List(vec![Value(2)]), Value(9)]))
    }

    #[test]
    fn test_parser() {
        let out = parse(INPUT)
            .iter()
            .map(|p| format!("{}\n{}", p.left, p.right))
            .collect::<Vec<String>>()
            .join("\n\n")
            + "\n";
        assert_eq!(out, INPUT);
    }
}
