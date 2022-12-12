use std::collections::{HashMap, HashSet, VecDeque};

const INPUT: &str = include_str!("../../input/day12.txt");

fn main() {
    let (hill, start, goal) = Hill::parse(INPUT);

    println!("Part 1: {}", part1(&hill, start, goal));
    println!("Part 2: {}", part2(&hill, goal));
}

fn part1(hill: &Hill, start: RC, goal: RC) -> usize {
    hill.bfs(start, goal).unwrap()
}

fn part2(hill: &Hill, goal: RC) -> usize {
    hill.starts()
        .iter()
        .filter_map(|a| hill.bfs(*a, goal))
        .min()
        .unwrap()
}

type RC = (isize, isize);

struct Hill {
    map: HashMap<RC, u32>,
}

impl Hill {
    fn parse(input: &str) -> (Self, RC, RC) {
        let mut map: HashMap<RC, u32> = HashMap::new();
        let mut start: Option<RC> = None;
        let mut goal: Option<RC> = None;

        let lines: Vec<&str> = aoc::lines(input).collect();

        for (r, line) in lines.iter().enumerate() {
            for (c, mut letter) in line.chars().enumerate() {
                let (r, c) = (r.try_into().unwrap(), c.try_into().unwrap());

                if letter == 'S' {
                    start = Some((r, c));
                    letter = 'a';
                }
                if letter == 'E' {
                    goal = Some((r, c));
                    letter = 'z';
                }

                let elevation = (letter as u32) - ('a' as u32);

                map.insert((r, c), elevation);
            }
        }

        (Self { map }, start.unwrap(), goal.unwrap())
    }

    fn bfs(&self, start: RC, goal: RC) -> Option<usize> {
        let mut queue: VecDeque<(RC, usize)> = VecDeque::new();
        let mut visited: HashSet<RC> = HashSet::new();

        queue.push_back((start, 0));

        while !queue.is_empty() {
            let (rc, cost) = queue.pop_front().unwrap();

            if visited.contains(&rc) {
                continue;
            }

            if rc == goal {
                return Some(cost);
            }

            for next in self.neighbors(rc) {
                queue.push_back((next, cost + 1));
            }

            visited.insert(rc);
        }

        None
    }

    fn neighbors(&self, (r, c): RC) -> Vec<RC> {
        let Some(h) = self.height((r, c)) else { return vec![] };

        [
            (-1, 0), // Up
            (1, 0),  // Down
            (0, -1), // Left
            (0, 1),  // Right
        ]
        .iter()
        .filter_map(|(dr, dc)| {
            let neighbor = (r + dr, c + dc);
            let Some(height) = self.height(neighbor) else { return None };

            if height <= h + 1 {
                Some(neighbor)
            } else {
                None
            }
        })
        .collect()
    }

    fn height(&self, (r, c): RC) -> Option<u32> {
        self.map.get(&(r, c)).copied()
    }

    fn starts(&self) -> Vec<RC> {
        let mut a = vec![];
        for (rc, h) in self.map.iter() {
            if h == &0 {
                a.push(*rc);
            }
        }
        a
    }
}
