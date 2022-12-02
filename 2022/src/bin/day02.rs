use std::str::FromStr;

const INPUT: &str = include_str!("../../input/day02.txt");

fn main() {
    println!("{:?}", part1(INPUT));
    println!("{:?}", part2(INPUT));
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum Play {
    Rock,
    Paper,
    Scissors,
}

impl FromStr for Play {
    type Err = std::convert::Infallible; // lol

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            // Opponent
            "A" => Ok(Self::Rock),
            "B" => Ok(Self::Paper),
            "C" => Ok(Self::Scissors),

            // Player
            "X" => Ok(Self::Rock),
            "Y" => Ok(Self::Paper),
            "Z" => Ok(Self::Scissors),

            _ => panic!("unknown play: {}", s),
        }
    }
}

#[derive(Debug, Clone)]
struct Round {
    opponent: Play,
    player: Play,
}

impl Round {
    fn score(&self) -> u32 {
        use Play::*;

        let shape = match self.player {
            Rock => 1,
            Paper => 2,
            Scissors => 3,
        };

        let outcome = match (self.opponent, self.player) {
            // Win
            (Rock, Paper) => 6,
            (Paper, Scissors) => 6,
            (Scissors, Rock) => 6,

            // Tie
            (Rock, Rock) => 3,
            (Paper, Paper) => 3,
            (Scissors, Scissors) => 3,

            // Loss
            (Rock, Scissors) => 0,
            (Paper, Rock) => 0,
            (Scissors, Paper) => 0,
        };

        shape + outcome
    }
}

fn part1(input: &str) -> u32 {
    let lines = input.split('\n').filter(|l| !l.is_empty());
    let rounds: Vec<Round> = lines
        .map(|l| {
            let parts: Vec<&str> = l.split(' ').collect();
            Round {
                opponent: Play::from_str(parts[0]).unwrap(),
                player: Play::from_str(parts[1]).unwrap(),
            }
        })
        .collect();

    rounds.iter().map(Round::score).sum()
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
enum Outcome {
    Loss,
    Tie,
    Win,
}

impl FromStr for Outcome {
    type Err = std::convert::Infallible; // lol

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "X" => Ok(Self::Loss),
            "Y" => Ok(Self::Tie),
            "Z" => Ok(Self::Win),

            _ => panic!("unknown play: {}", s),
        }
    }
}

impl Outcome {
    fn respond(&self, opponent: Play) -> Play {
        use Outcome::*;
        use Play::*;

        match (self, opponent) {
            (Loss, Rock) => Scissors,
            (Loss, Paper) => Rock,
            (Loss, Scissors) => Paper,
            (Tie, Rock) => Rock,
            (Tie, Paper) => Paper,
            (Tie, Scissors) => Scissors,
            (Win, Rock) => Paper,
            (Win, Paper) => Scissors,
            (Win, Scissors) => Rock,
        }
    }
}

fn part2(input: &str) -> u32 {
    let lines = input.split('\n').filter(|l| !l.is_empty());
    let rounds: Vec<Round> = lines
        .map(|l| {
            let parts: Vec<&str> = l.split(' ').collect();

            let opponent = Play::from_str(parts[0]).unwrap();
            let outcome = Outcome::from_str(parts[1]).unwrap();

            let player = outcome.respond(opponent);

            Round { opponent, player }
        })
        .collect();

    rounds.iter().map(Round::score).sum()
}
