use std::collections::HashMap;

extern crate regex;

const INPUT: &str = include_str!("input/day4.txt");
// const INPUT: &str = include_str!("input/day4_test.txt");

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord, Clone)]
struct Timestamp {
    date: String,
    hour: u32,
    minute: u32,
}

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord)]
enum Event {
    WokeUp,
    FellAsleep,
    ShiftChange(String),
}

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord)]
struct Entry {
    timestamp: Timestamp,
    event: Event,
}

fn parse_input() -> Vec<Entry> {
    let re: regex::Regex =
        regex::Regex::new(r"^\[(\d{4}-\d{2}-\d{2}) (\d{2}):(\d{2})] (.*)$").unwrap();
    let re_shift: regex::Regex = regex::Regex::new(r"^Guard #(\d+) begins shift$").unwrap();
    let mut entries = Vec::new();
    for line in str::lines(INPUT) {
        let caps = re.captures(line).unwrap();
        let date = caps.get(1).unwrap().as_str().to_string();
        let hour = caps.get(2).unwrap().as_str().to_string().parse().unwrap();
        let minute = caps.get(3).unwrap().as_str().to_string().parse().unwrap();
        let ev = match caps.get(4).unwrap().as_str() {
            "wakes up" => Event::WokeUp,
            "falls asleep" => Event::FellAsleep,
            shift => {
                let caps = re_shift.captures(shift).unwrap();
                Event::ShiftChange(caps.get(1).unwrap().as_str().to_string())
            }
        };
        entries.push(Entry {
            timestamp: Timestamp {
                date: date,
                hour: hour,
                minute: minute,
            },
            event: ev,
        });
    }
    entries
}

#[derive(Debug, Clone)]
enum State {
    Awake,
    Asleep,
}

#[derive(Debug, Clone)]
struct Minute {
    timestamp: Timestamp,
    guard: String,
    state: State,
}

fn get_events(entries: &mut Vec<Entry>) -> Vec<Minute> {
    entries.sort();
    match entries[0].event {
        Event::ShiftChange(_) => (),
        _ => panic!("Invalid entry list!"),
    }

    let mut states = Vec::new();
    let mut guard = "".to_string();
    for e in entries {
        let m = match &e.event {
            Event::ShiftChange(g) => {
                guard = g.to_string();
                Minute {
                    timestamp: e.timestamp.clone(),
                    guard: guard.to_string(),
                    state: State::Awake,
                }
            }
            Event::FellAsleep => Minute {
                timestamp: e.timestamp.clone(),
                guard: guard.to_string(),
                state: State::Asleep,
            },
            Event::WokeUp => Minute {
                timestamp: e.timestamp.clone(),
                guard: guard.to_string(),
                state: State::Awake,
            },
        };
        states.push(m);
    }
    states
}

fn sleep_intervals(ms: Vec<Minute>) -> Vec<((String, u32, u32))> {
    let mut i = 0;
    let mut ps = Vec::new();
    while i + 1 < ms.len() {
        let p1 = ms[i].clone();
        let p2 = ms[i + 1].clone();
        match (p1, p2) {
            (
                Minute {
                    timestamp:
                        Timestamp {
                            date: _,
                            hour: _,
                            minute: m1,
                        },
                    guard: g1,
                    state: State::Asleep,
                },
                Minute {
                    timestamp:
                        Timestamp {
                            date: _,
                            hour: _,
                            minute: m2,
                        },
                    guard: g2,
                    state: State::Awake,
                },
            ) => {
                if g1 == g2 {
                    ps.push((g1, m1, m2));
                }
            }
            _ => {}
        }
        i += 1;
    }
    ps
}

fn mode(ms: Vec<u32>) -> u32 {
    let mut buckets = HashMap::new();
    for m in ms {
        let mut b = buckets.entry(m).or_insert(0);
        *b += 1;
    }
    let mut elts: Vec<(&u32, &u32)> = buckets.iter().collect();
    elts.sort_by(|l, r| r.1.cmp(l.1));
    *(elts[0].0)
}

fn interpolate_sleep(sleeps: Vec<(String, u32, u32)>) -> HashMap<String, Vec<u32>> {
    let mut minutes_asleep: HashMap<String, Vec<u32>> = HashMap::new();
    for (g, m1, m2) in sleeps {
        let mut ms = minutes_asleep.entry(g).or_insert(Vec::new());
        let mut m = m1;
        while m < m2 {
            ms.push(m);
            m += 1;
        }
    }
    minutes_asleep
}

fn sleep_data() -> HashMap<String, Vec<u32>> {
    let mut input = parse_input();
    let events = get_events(&mut input);
    let sleeps = sleep_intervals(events);
    let minutes_asleep = interpolate_sleep(sleeps);
    minutes_asleep
}

pub fn part1() -> u32 {
    let mut most_asleep = ("".to_string(), Vec::new());
    for (g, ms) in sleep_data() {
        if ms.len() > most_asleep.1.len() {
            most_asleep = (g, ms);
        }
    }

    let guard = most_asleep.0.parse::<u32>().unwrap();
    let minute = mode(most_asleep.1);
    minute * guard
}

fn mode2(ms: Vec<(u32, u32)>) -> (u32, u32) {
    let mut buckets = HashMap::new();
    for m in ms {
        let mut b = buckets.entry(m).or_insert(0);
        *b += 1;
    }
    let mut elts: Vec<(&(u32, u32), &u32)> = buckets.iter().collect();
    elts.sort_by(|l, r| r.1.cmp(l.1));
    *(elts[0].0)
}

pub fn part2() -> u32 {
    let mut points: Vec<(u32, u32)> = Vec::new();
    for (g, ms) in sleep_data() {
        for m in ms {
            points.push((g.parse::<u32>().unwrap(), m.clone()));
        }
    }
    let (g, m) = mode2(points);
    g * m
}
