use std::collections::{BinaryHeap, HashMap, HashSet};

const INPUT: &str = include_str!("../../input/day23.txt");

fn main() {
    let valley = Valley::parse(INPUT);
    println!("{}", part1(valley));
}

type RC = (usize, usize);

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum Direction {
    North,
    East,
    South,
    West,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum Entity {
    Wall,
    Blizzard(Direction),
}

#[derive(Debug, Clone)]
struct Valley {
    grid: HashMap<RC, Entity>,
    start: RC,
    goal: RC,
    height: usize,
    width: usize,
}

impl Valley {
    fn parse(text: &str) -> Self {
        let mut grid: HashMap<RC, Entity> = HashMap::new();

        let lines: Vec<&str> = text.lines().collect();

        for (r, line) in lines.iter().enumerate() {
            for (c, fill) in line.chars().enumerate() {
                let entity = match fill {
                    '.' => continue,
                    '#' => Entity::Wall,
                    '^' => Entity::Blizzard(Direction::North),
                    '>' => Entity::Blizzard(Direction::East),
                    'v' => Entity::Blizzard(Direction::South),
                    '<' => Entity::Blizzard(Direction::West),
                    other => panic!("{:?}", other),
                };
                let old = grid.insert((r, c), entity);
                assert!(old.is_none());
            }
        }

        let height = lines.len();
        let width = lines[0].len();

        let mut start = (0, 0);
        for (c, fill) in lines[0].chars().enumerate() {
            if fill == '.' {
                start = (0, c);
            }
        }

        let mut goal = (0, 0);
        for (c, fill) in lines[lines.len() - 1].chars().enumerate() {
            if fill == '.' {
                goal = (lines.len() - 1, c);
            }
        }

        let valley = Self {
            grid: grid.clone(),
            start,
            goal,
            width,
            height,
        };

        valley.check();
        valley
    }

    fn check(&self) {
        assert_eq!(self.start, (0, 1));
        assert_eq!(self.goal, (self.height - 1, self.width - 2));

        for (&loc @ (r, c), ent) in &self.grid {
            assert!(!self.safe(0, loc), "{:?}", ent);
            assert!(r < self.height);
            assert!(c < self.width);
        }

        assert!(self.safe(0, self.start));
        assert!(self.safe(0, self.goal));
    }

    fn safe(&self, minutes: usize, loc @ (r, c): RC) -> bool {
        if r >= self.height || c >= self.width {
            // Out of bounds!
            return false;
        }

        // TODO: is it faster to just slice the row and column out?
        for (&start, &entity) in &self.grid {
            match entity {
                Entity::Wall => {
                    if loc == start {
                        // Can't stand here.
                        return false;
                    }
                }

                Entity::Blizzard(dir) => {
                    if self.blizzard_pos(minutes, start, dir) == loc {
                        // Oops!
                        return false;
                    }
                }
            }
        }

        // No danger... for now!
        true
    }

    fn blizzard_pos(&self, minutes: usize, (r, c): RC, dir: Direction) -> RC {
        // Two walls, always.
        let rr = self.height - 2;
        let cc = self.width - 2;

        fn sub_mod(a: usize, b: usize, m: usize) -> usize {
            let a: i64 = a.try_into().unwrap();
            let b: i64 = b.try_into().unwrap();
            let m: i64 = m.try_into().unwrap();
            ((((a - b) % m) + m) % m).try_into().unwrap()
        }

        fn add_mod(a: usize, b: usize, m: usize) -> usize {
            (a + b) % m
        }

        // Subtract 1 to get into a wall-less space, and then add it back to get back to
        // normal.
        match dir {
            Direction::North => (1 + sub_mod(r - 1, minutes, rr), c),
            Direction::South => (1 + add_mod(r - 1, minutes, rr), c),

            Direction::West => (r, 1 + sub_mod(c - 1, minutes, cc)),
            Direction::East => (r, 1 + add_mod(c - 1, minutes, cc)),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct State {
    loc: RC,
    minutes: usize,
    heuristic: usize,
}

impl State {
    fn sort_cost(&self) -> usize {
        self.minutes + self.heuristic
    }

    fn destinations(&self) -> Vec<RC> {
        let (r, c) = self.loc;
        // If the search ever tries the start state again, this has to handle it. Somehow my search
        // actually gets here _twice_, even if I pre-excute the first step to get into the grid.
        let mut v = vec![];
        if r > 0 {
            v.push((r - 1, c));
        }

        v.push((r, c - 1));
        v.push((r, c));
        v.push((r, c + 1));

        v.push((r + 1, c));

        v
    }
}

impl PartialOrd for State {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for State {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        // BinaryHeap is a **MAX-HEAP**. To get a min-heap, we run the comparisons backwards.
        other.sort_cost().cmp(&self.sort_cost())
    }
}

fn part1(valley: Valley) -> usize {
    let mut queue: BinaryHeap<State> = BinaryHeap::new();
    let mut expanded: HashSet<State> = HashSet::new();

    let goal = valley.goal;

    let heuristic = move |loc: RC| -> usize {
        let dr = goal.0 - loc.0;
        let dc = goal.1 - loc.1;
        dr + dc
    };

    let successors = move |state: &State| -> Vec<State> {
        let minutes = state.minutes + 1;

        state
            .destinations()
            .iter()
            .map(|&loc| State {
                loc,
                minutes,
                heuristic: 0,
            })
            .collect()
    };

    let start = State {
        minutes: 0,
        loc: valley.start,
        heuristic: 0,
    };
    queue.push(start);

    while let Some(state) = queue.pop() {
        if !expanded.insert(state.clone()) {
            continue;
        }

        let progress = expanded.len();
        if progress % 1000 == 0 {
            dbg!(progress);
        }

        if state.loc == goal {
            return state.minutes;
        };

        for mut next in successors(&state) {
            if valley.safe(next.minutes, next.loc) {
                next.heuristic = heuristic(next.loc);
                queue.push(next);
            }
        }
    }

    dbg!(expanded);
    panic!("Caught in a blizzard 🥶")
}
