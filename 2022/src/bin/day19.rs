use std::{
    collections::{BTreeMap, HashMap, VecDeque},
    str::FromStr,
};

use regex::Regex;
use serde::{
    de::{value, IntoDeserializer},
    Deserialize,
};

const INPUT: &str = include_str!("../../input/day19.txt");

fn main() {
    let blueprints: Vec<Blueprint> = aoc::lines(INPUT).map(Blueprint::parse).collect();
    println!("{}", part1(&blueprints));
    println!("{}", part2(&blueprints[..3]));
}

#[derive(Debug, Clone)]
struct Blueprint {
    id: usize,
    recipes: Vec<Recipe>,
}

impl Blueprint {
    fn parse(line: &str) -> Self {
        let id: usize = {
            let re = Regex::new(r"^Blueprint (\d+):").unwrap();
            let caps = re.captures(line).unwrap();
            caps[1].parse().unwrap()
        };

        let recipes = Recipe::parse_all(line);

        Self { id, recipes }
    }

    fn id(&self) -> u64 {
        self.id.try_into().unwrap()
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct Recipe {
    resource: Resource,
    costs: HashMap<Resource, u64>,
}

impl Recipe {
    fn parse_all(line: &str) -> Vec<Self> {
        let re = Regex::new(r"Each (.*?) robot costs ([^.]*).").unwrap();

        let mut recipes = vec![];
        for caps in re.captures_iter(line) {
            let resource = Resource::from_str(&caps[1]).unwrap();

            let mut costs = HashMap::new();
            for phrase in caps[2].split(" and ") {
                let words: Vec<&str> = aoc::words(phrase).collect();
                let n: u64 = words[0].parse().unwrap();
                let res = Resource::from_str(words[1]).unwrap();

                let old = costs.insert(res, n);
                assert!(old.is_none());
            }

            recipes.push(Self { resource, costs });
        }

        recipes
    }
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, PartialOrd, Ord, Hash, Deserialize)]
#[serde(rename_all = "lowercase")]
enum Resource {
    Ore,
    Clay,
    Obsidian,
    Geode,
}

impl Resource {
    const ALL: [Resource; 4] = [Self::Ore, Self::Clay, Self::Obsidian, Self::Geode];
}

impl FromStr for Resource {
    type Err = value::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Self::deserialize(s.into_deserializer())
    }
}

fn part1(blueprints: &[Blueprint]) -> u64 {
    blueprints
        .iter()
        .cloned()
        .map(|bp| bp.id() * geodes_mined(bp, 24))
        .sum()
}

fn part2(blueprints: &[Blueprint]) -> u64 {
    blueprints
        .iter()
        .cloned()
        .map(|bp| geodes_mined(bp, 32))
        .product()
}

fn geodes_mined(blueprint: Blueprint, total_minutes: u64) -> u64 {
    dbg!(&blueprint.id);

    let factory = Factory::new(blueprint);

    let mut queue: VecDeque<State> = VecDeque::new();

    let start = State::start(total_minutes);
    queue.push_front(start.clone());

    let mut bests: DefaultDict<u64, u64> = DefaultDict::new();
    bests.insert(start.minutes_left, start.geodes());

    while let Some(state) = queue.pop_front() {
        let best_known = bests.get(&state.minutes_left);
        if state.optimistic_geodes() <= best_known {
            // This branch of the tree can't possibly do better.
            continue;
        }

        bests.modify(state.minutes_left, |best| best.max(state.geodes()));

        for next in state.successors(&factory) {
            queue.push_front(next);
        }
    }

    bests.get(&0)
}

impl Blueprint {
    fn robot_costs(&self) -> HashMap<Resource, HashMap<Resource, u64>> {
        let mut costs = HashMap::new();

        for robot_type in Resource::ALL {
            costs.insert(robot_type, self.costs(robot_type));
        }

        costs
    }

    fn costs(&self, robot_type: Resource) -> HashMap<Resource, u64> {
        let recipe = self
            .recipes
            .iter()
            .find(|r| r.resource == robot_type)
            .unwrap();
        recipe.costs.clone()
    }

    fn max_usable(&self) -> DefaultDict<Resource, u64> {
        let mut max: DefaultDict<Resource, u64> = DefaultDict::new();
        for r in &self.recipes {
            for (&res, &amount) in &r.costs {
                let old = max.get(&res);
                max.insert(res, old.max(amount));
            }
        }
        max
    }
}

#[derive(Debug, Clone)]
struct Factory {
    robot_costs: HashMap<Resource, HashMap<Resource, u64>>,
    max_usable: DefaultDict<Resource, u64>,
}

impl Factory {
    fn new(blueprint: Blueprint) -> Self {
        Self {
            robot_costs: blueprint.robot_costs(),
            max_usable: blueprint.max_usable(),
        }
    }
}

impl Factory {
    fn can_build(&self, robot_type: Resource, items: &DefaultDict<Resource, u64>) -> bool {
        let costs = self.robot_costs.get(&robot_type).unwrap();

        costs.iter().all(|(&res, &want)| {
            let have = items.get(&res);
            have >= want
        })
    }

    fn should_build(&self, robot_type: Resource, robots: &DefaultDict<Resource, u64>) -> bool {
        if robot_type == Resource::Geode {
            return true;
        }

        let production = robots.get(&robot_type);
        let usage = self.max_usable.get(&robot_type);

        production < usage
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct State {
    minutes_left: u64,

    robots: DefaultDict<Resource, u64>,
    items: DefaultDict<Resource, u64>,
}

impl std::fmt::Display for State {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        writeln!(f, "Robots: {:?}", self.robots)?;
        writeln!(f, "Items: {:?}", self.items)?;
        Ok(())
    }
}

impl State {
    fn start(minutes_left: u64) -> Self {
        let mut robots = DefaultDict::new();
        robots.insert(Resource::Ore, 1);

        Self {
            minutes_left,
            robots,
            items: Default::default(),
        }
    }

    fn geodes(&self) -> u64 {
        self.items.get(&Resource::Geode)
    }
}

impl State {
    fn tick(&mut self, factory: &Factory, robot_type: Option<Resource>) {
        if let Some(robot_type) = robot_type {
            self.start_building(factory, robot_type);
        }

        self.mine();

        if let Some(robot_type) = robot_type {
            self.add_robot(robot_type);
        }

        self.minutes_left -= 1;
    }

    fn start_building(&mut self, factory: &Factory, robot_type: Resource) {
        for (&res, &cost) in factory.robot_costs.get(&robot_type).unwrap() {
            self.items.modify(res, |have| have - cost);
        }
    }

    fn mine(&mut self) {
        for (&res, &mined) in &self.robots.0 {
            self.items.modify(res, |have| have + mined);
        }
    }

    fn add_robot(&mut self, robot_type: Resource) {
        self.robots.modify(robot_type, |have| have + 1);
    }
}

impl State {
    fn optimistic_geodes(&self) -> u64 {
        let dt = self.minutes_left;

        let geode_rate = self.robots.get(&Resource::Geode);
        let guaranteed = geode_rate * dt;

        // Build a geode miner every turn and sum the extra outputs.
        let magic_mining = triangle(dt);

        self.geodes() + guaranteed + magic_mining
    }

    fn successors(&self, factory: &Factory) -> Vec<Self> {
        // The search should never try this, but just in case...
        if self.minutes_left == 0 {
            return vec![];
        }

        // There are exactly five possible worlds:
        let mut states = vec![];

        // 1-4: Build a robot of type X.
        //
        // By assumption, all timesteps between now and the actual robot build step _must_ be
        // idling steps.
        for robot_type in Resource::ALL {
            // Avoid building a robot whose output would never get used.
            if !factory.should_build(robot_type, &self.robots) {
                continue;
            }

            let mut next = self.clone();

            // Idle-mine until the robot can be built.
            //
            // TODO: I'm sure there's a simple inequality for this.
            while next.minutes_left > 0 && !factory.can_build(robot_type, &next.items) {
                next.tick(factory, None);
            }

            // Build the robot if there's any time left.
            if next.minutes_left > 0 {
                next.tick(factory, Some(robot_type));
                states.push(next);
            }
        }

        // 5: Never build a robot again, ever.
        //
        // Skip directly to the end by idle-mining all the time away.
        {
            let mut next = self.clone();
            while next.minutes_left > 0 {
                next.tick(factory, None);
            }
            states.push(next);
        }

        states
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct DefaultDict<K, V>(BTreeMap<K, V>)
where
    K: Eq + std::hash::Hash,
    V: Default + Clone;

impl<K, V> DefaultDict<K, V>
where
    K: Eq + std::hash::Hash + std::cmp::Ord,
    V: Default + Clone,
{
    fn new() -> Self {
        Self(BTreeMap::new())
    }

    fn insert(&mut self, key: K, val: V) -> Option<V> {
        self.0.insert(key, val)
    }

    fn get(&self, key: &K) -> V {
        if let Some(v) = self.0.get(key) {
            v.clone()
        } else {
            V::default()
        }
    }

    fn modify<F>(&mut self, key: K, f: F) -> V
    where
        F: FnOnce(V) -> V,
    {
        let old = self.get(&key);
        let new = f(old);
        self.insert(key, new.clone());
        new
    }
}

impl<K, V> Default for DefaultDict<K, V>
where
    K: Eq + std::hash::Hash,
    V: Default + Clone,
{
    fn default() -> Self {
        Self(Default::default())
    }
}

fn triangle(n: u64) -> u64 {
    (n * (n + 1)) / 2
}
