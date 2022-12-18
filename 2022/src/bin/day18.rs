const INPUT: &str = include_str!("../../input/day18.txt");

fn main() {
    println!("{}", part1(INPUT));
}

fn part1(input: &str) -> usize {
    let cubes: Vec<Cube> = aoc::lines(input)
        .map(|line| {
            let coords: Vec<&str> = line.split(',').collect();
            let x = coords[0].parse().unwrap();
            let y = coords[1].parse().unwrap();
            let z = coords[2].parse().unwrap();
            Cube::new(x, y, z)
        })
        .collect();

    let mut shared_faces = 0;
    for (c1, c2) in itertools::iproduct!(&cubes, &cubes) {
        if c1 == c2 {
            continue;
        }

        if c1.touches(c2) {
            shared_faces += 1;
        }
    }

    6 * cubes.len() - shared_faces
}

#[derive(Debug, Copy, Clone, PartialEq, Eq)]
struct Cube {
    x: u32,
    y: u32,
    z: u32,
}

impl Cube {
    fn new(x: u32, y: u32, z: u32) -> Self {
        Self { x, y, z }
    }

    fn touches(&self, other: &Self) -> bool {
        let dx = (self.x as i32 - other.x as i32).abs();
        let dy = (self.y as i32 - other.y as i32).abs();
        let dz = (self.z as i32 - other.z as i32).abs();
        (dx + dy + dz) == 1
    }
}
