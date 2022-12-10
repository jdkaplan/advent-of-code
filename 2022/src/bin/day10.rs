const INPUT: &str = include_str!("../../input/day10.txt");

fn main() {
    let instructions = parse(INPUT);

    let mut crt = Crt::new();

    for i in instructions {
        crt.run(i);
    }

    println!("Part 1: {}", crt.strength);
    println!("{}", crt.image);
}

#[derive(Debug, Copy, Clone)]
enum Instruction {
    Noop,
    Addx(i64),
}

fn parse(input: &str) -> Vec<Instruction> {
    aoc::split_lines(input)
        .iter()
        .map(|line| {
            let w = aoc::split_words(line);
            match w[0] {
                "noop" => Instruction::Noop,
                "addx" => Instruction::Addx(w[1].parse().unwrap()),
                other => panic!("{}", other),
            }
        })
        .collect()
}

#[derive(Debug, Clone)]
struct Crt {
    cycle: usize,
    x: i64,

    strength: i64,
    image: String,
}

impl Crt {
    fn new() -> Self {
        Self {
            cycle: 0,
            x: 1,

            strength: 0,
            image: String::new(),
        }
    }

    fn run(&mut self, i: Instruction) {
        let dxs = match i {
            Instruction::Noop => vec![0],
            Instruction::Addx(dx) => vec![0, dx],
        };

        for dx in dxs {
            let scanx = (self.cycle as i64) % 40;
            if scanx == 0 {
                self.image += "\n";
            }

            self.cycle += 1;

            let pixel = if (self.x - scanx).abs() < 2 { "#" } else { "." };
            self.image += pixel;

            let signal = (self.cycle as i64) * self.x;
            if (self.cycle + 20) % 40 == 0 {
                self.strength += signal;
            }

            self.x += dx;
        }
    }
}
