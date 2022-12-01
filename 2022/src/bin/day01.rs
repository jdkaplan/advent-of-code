const INPUT: &str = include_str!("../../input/day01.txt");

fn main() {
    println!("{}", part1(INPUT).unwrap());
    println!("{}", part2(INPUT).unwrap());
}

#[derive(Debug, Clone, Default)]
struct Elf {
    fruits: Vec<u32>,
}

impl Elf {
    fn total(&self) -> u32 {
        self.fruits.iter().sum()
    }
}

fn part1(input: &str) -> anyhow::Result<u32> {
    let mut elves: Vec<Elf> = vec![];

    for section in input.split("\n\n") {
        let mut elf = Elf::default();

        for fruit in section.split('\n').filter(|line| !line.is_empty()) {
            let cals: u32 = fruit.parse()?;
            elf.fruits.push(cals);
        }

        elves.push(elf);
    }

    let most_food = elves.iter().cloned().max_by_key(Elf::total).unwrap();
    Ok(most_food.total())
}

fn part2(input: &str) -> anyhow::Result<u32> {
    let mut elves: Vec<Elf> = vec![];

    for section in input.split("\n\n") {
        let mut elf = Elf::default();

        for fruit in section.split('\n').filter(|line| !line.is_empty()) {
            let cals: u32 = fruit.parse()?;
            elf.fruits.push(cals);
        }

        elves.push(elf);
    }

    elves[..].sort_by_key(|e| std::cmp::Reverse(e.total()));
    Ok(elves[0..3].iter().map(Elf::total).sum())
}
