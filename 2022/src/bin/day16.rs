use std::{
    collections::{BinaryHeap, HashMap, HashSet},
    str::FromStr,
};

use regex::Regex;

const INPUT: &str = include_str!("../../input/day16.txt");

fn main() {
    let graph = Graph::parse(INPUT);

    println!("{}", graph.max_flow(30).flow);
    println!("{}", graph.max_flow_with_an_elephriend(26));
}

// I really want this to be Copy, so here's a hack to avoid strings.
#[derive(Debug, Copy, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
struct Valve(u64);

impl FromStr for Valve {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        if s.len() != 2 {
            return Err(s.to_string());
        }

        let u = s
            .chars()
            .rev()
            .enumerate()
            .map(|(i, c)| (c as u64) << (8 * i))
            .sum();

        Ok(Self(u))
    }
}

impl From<&str> for Valve {
    fn from(value: &str) -> Self {
        Self::from_str(value).unwrap()
    }
}

impl std::fmt::Display for Valve {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let u = self.0;
        write!(
            f,
            "{}{}",
            char::from_u32((u >> 8).try_into().unwrap()).unwrap(),
            char::from_u32((u & 0xff).try_into().unwrap()).unwrap()
        )
    }
}

type Flow = u32;
type Pressure = u32;

#[derive(Debug, Clone)]
struct Graph {
    valves: HashMap<Valve, Pressure>,
    tunnels: HashMap<Valve, Vec<Valve>>,
}

impl Graph {
    fn parse(text: &str) -> Self {
        let mut valves = HashMap::new();
        let mut tunnels: HashMap<Valve, Vec<Valve>> = HashMap::new();

        let re = Regex::new(r"^Valve (.*) has flow rate=(.*); tunnels? leads? to valves? (.*)$")
            .unwrap();

        for line in aoc::lines(text) {
            let caps = re.captures(line).unwrap();

            let valve = Valve::from_str(&caps[1]).unwrap();
            let flow_rate: u32 = caps[2].parse().unwrap();
            let neighbors: Vec<Valve> =
                caps[3].split(", ").map(|s| s.try_into().unwrap()).collect();

            valves.insert(valve, flow_rate);
            for n in neighbors {
                tunnels
                    .entry(valve)
                    .and_modify(|dests| dests.push(n))
                    .or_insert_with(|| vec![n]);
            }
        }

        Self { valves, tunnels }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
enum Action {
    MoveTo(Valve),
    Open(Valve),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct Path(Vec<Action>);

impl Path {
    fn current_location(&self) -> Valve {
        match self.0.last() {
            None => Valve::from("AA"),
            Some(Action::MoveTo(v)) => *v,
            Some(Action::Open(v)) => *v,
        }
    }

    fn minutes_elapsed(&self) -> usize {
        self.0.len()
    }

    fn successors(
        &self,
        valves: &HashMap<Valve, Pressure>,
        paths: &HashMap<(Valve, Valve), Option<ShortestPath<Valve>>>,
    ) -> Vec<Vec<Action>> {
        let here = self.current_location();

        let open_valves: HashSet<Valve> = self
            .0
            .iter()
            .cloned()
            .filter_map(|a| match a {
                Action::Open(v) => Some(v),
                Action::MoveTo(_) => None,
            })
            .collect();

        let mut suffixes = vec![];

        for (&dest, &pressure) in valves {
            if pressure == 0 {
                continue;
            }
            if open_valves.contains(&dest) {
                continue;
            }

            let Some(ref sp) = paths[&(here, dest)] else {
                continue;
            };

            let mut actions = vec![];
            for &node in &sp.nodes[1..] {
                // skip self start
                actions.push(Action::MoveTo(node));
            }
            actions.push(Action::Open(dest));

            suffixes.push(actions);
        }

        suffixes
    }

    fn flow(&self, valves: &HashMap<Valve, Pressure>, total_minutes: usize) -> Flow {
        self.0
            .iter()
            .enumerate()
            .map(|(i, a)| {
                let pressure = match a {
                    Action::MoveTo(_) => 0,
                    Action::Open(ref v) => valves[v],
                };
                let minutes_left = total_minutes - i - 1;
                pressure * (minutes_left as u32)
            })
            .sum()
    }
}

#[derive(Debug, Clone, Eq, PartialEq)]
struct State {
    path: Path,
    flow: Flow,
}

impl PartialOrd for State {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for State {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        // BinaryHeap is a **MAX-HEAP**. To get a min-heap, we run the comparisons backwards.

        let self_minutes = self.path.minutes_elapsed();
        let other_minutes = other.path.minutes_elapsed();

        // Sort more remaining time first...
        let cmp_minutes = self_minutes.cmp(&other_minutes);

        // ... and break ties by higher flow.
        cmp_minutes.then_with(|| other.flow.cmp(&self.flow))
    }
}

impl Graph {
    fn max_flow(&self, total_minutes: usize) -> State {
        let paths = {
            let nodes: Vec<Valve> = self.valves.keys().cloned().collect();
            let mut edges: HashMap<(Valve, Valve), u64> = HashMap::new();
            for (&from, tos) in &self.tunnels {
                for &to in tos {
                    edges.insert((from, to), 1);
                }
            }
            all_pairs_shortest_paths(nodes, edges)
        };

        let mut queue: BinaryHeap<State> = BinaryHeap::new();
        let mut expanded: HashSet<Valve> = HashSet::new();

        let start = State {
            path: Path(vec![]),
            flow: 0,
        };

        queue.push(start.clone());

        let mut best: State = start;

        while let Some(state) = queue.pop() {
            let here = state.path.current_location();
            expanded.insert(here);

            if state.flow > best.flow {
                best = state.clone();
            }

            for actions in state.path.successors(&self.valves, &paths) {
                let path = {
                    let mut aa = state.path.0.clone();
                    aa.extend(actions);
                    Path(aa)
                };

                if path.minutes_elapsed() > total_minutes {
                    // 🌋🌋🌋
                    continue;
                }

                let flow = path.flow(&self.valves, total_minutes);

                queue.push(State { path, flow });
            }
        }

        best
    }

    fn max_flow_with_an_elephriend(&self, total_minutes: usize) -> Flow {
        let best = self.max_flow(total_minutes);

        let elegraph = {
            let mut g = self.clone();
            for action in best.path.0 {
                if let Action::Open(v) = action {
                    g.valves.insert(v, 0);
                }
            }
            g
        };
        let elebest = elegraph.max_flow(total_minutes);

        best.flow + elebest.flow
    }
}

#[derive(Debug, Clone)]
struct ShortestPath<V> {
    nodes: Vec<V>,
}

fn all_pairs_shortest_paths<V>(
    nodes: Vec<V>,
    edges: HashMap<(V, V), u64>,
) -> HashMap<(V, V), Option<ShortestPath<V>>>
where
    V: Eq + std::hash::Hash + Copy + core::fmt::Debug,
{
    let mut dist: HashMap<(V, V), u64> = HashMap::new();
    let mut next: HashMap<(V, V), V> = HashMap::new();

    for (&(u, v), &w) in &edges {
        dist.insert((u, v), w);
        next.insert((u, v), v);
        next.insert((v, u), u);
    }
    for &v in &nodes {
        dist.insert((v, v), 0);
        next.insert((v, v), v);
    }

    for &k in &nodes {
        for &i in &nodes {
            for &j in &nodes {
                let Some(d_ik) = dist.get(&(i,k)) else { continue };
                let Some(d_kj) = dist.get(&(k,j)) else { continue };
                let d_ikj = d_ik + d_kj;

                let Some(&d_ij) = dist.get(&(i,j)) else {
                    dist.insert((i, j) , d_ikj);
                    next.insert((i, j) , next[&(i,k)]);
                    continue;
                };

                if d_ij > d_ikj {
                    dist.insert((i, j), d_ikj);
                    next.insert((i, j), next[&(i, k)]);
                }
            }
        }
    }

    let mut paths: HashMap<(V, V), Option<ShortestPath<V>>> = HashMap::new();

    let find_path = |mut u: V, v: V| -> Option<Vec<V>> {
        let mut path = vec![u];

        while u != v {
            let Some(&k) = next.get(&(u, v)) else {
                return None
            };

            u = k;
            path.push(u);
        }
        Some(path)
    };

    for &i in &nodes {
        for &j in &nodes {
            let Some(nodes) = find_path(i, j) else {
                continue;
            };
            paths.insert((i, j), Some(ShortestPath { nodes }));
        }
    }

    paths
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn heap_order() {
        let mut queue: BinaryHeap<State> = BinaryHeap::new();

        let worse = State {
            path: Path(vec![Action::MoveTo("DD".into()), Action::Open("DD".into())]),
            flow: 560,
        };
        let better = State {
            path: Path(vec![
                Action::MoveTo("DD".into()),
                Action::MoveTo("BB".into()),
            ]),
            flow: 0,
        };
        queue.push(worse);
        queue.push(better.clone());

        assert_eq!(better, queue.pop().unwrap());
    }
}
