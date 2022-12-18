use std::collections::{HashMap, VecDeque};

const INPUT: &str = include_str!("../../input/day18.txt");

fn main() {
    let cubes = parse(INPUT);
    let open_faces = part1(cubes.clone());
    println!("Part 1: {}", open_faces);
    println!("Part 2: {}", part2(cubes, open_faces));
}

fn part1(cubes: Vec<Cube>) -> usize {
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

fn part2(cubes: Vec<Cube>, open_faces: usize) -> usize {
    let min = cubes.iter().map(Cube::min_coord).min().unwrap();
    let max = cubes.iter().map(Cube::max_coord).max().unwrap();

    let mut grid: HashMap<Cube, Material> = cubes
        .iter()
        .cloned()
        .map(|c| (c, Material::Water))
        .collect();

    let lo = Cube {
        x: min - 1,
        y: min - 1,
        z: min - 1,
    };

    let hi = Cube {
        x: max + 1,
        y: max + 1,
        z: max + 1,
    };

    grid.insert(lo, Material::Steam);
    grid.insert(hi, Material::Steam);

    steam(&mut grid, lo, hi);
    air(&mut grid, lo, hi);

    let mut insulated_faces = 0;
    for (&cube, &mat) in &grid {
        if mat == Material::Air {
            for neighbor in cube.neighbors() {
                if let Some(Material::Water) = grid.get(&neighbor) {
                    insulated_faces += 1;
                }
            }
        }
    }

    open_faces - insulated_faces
}

fn steam(grid: &mut HashMap<Cube, Material>, lo: Cube, hi: Cube) {
    let mut queue: VecDeque<Cube> = grid
        .iter()
        .filter_map(|(&cube, &mat)| {
            if mat == Material::Steam {
                Some(cube)
            } else {
                None
            }
        })
        .collect();

    while let Some(src) = queue.pop_front() {
        for dst in src.neighbors() {
            if dst.out_of_bounds(lo, hi) {
                continue;
            }

            if let Some(_mat) = grid.get(&dst) {
                continue;
            }

            let old = grid.insert(dst, Material::Steam);
            assert!(old.is_none());

            queue.push_back(dst);
        }
    }
}

fn air(grid: &mut HashMap<Cube, Material>, lo: Cube, hi: Cube) {
    for (x, y, z) in itertools::iproduct!(lo.x..=hi.x, lo.y..=hi.y, lo.z..=hi.z) {
        let cube = Cube::new(x, y, z);
        grid.entry(cube).or_insert(Material::Air);
    }
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
enum Material {
    Water,
    Steam,
    Air,
}

fn parse(input: &str) -> Vec<Cube> {
    aoc::lines(input)
        .map(|line| {
            let coords: Vec<&str> = line.split(',').collect();
            let x = coords[0].parse().unwrap();
            let y = coords[1].parse().unwrap();
            let z = coords[2].parse().unwrap();
            Cube::new(x, y, z)
        })
        .collect()
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct Cube {
    x: i32,
    y: i32,
    z: i32,
}

impl Cube {
    fn new(x: i32, y: i32, z: i32) -> Self {
        Self { x, y, z }
    }

    fn touches(&self, other: &Self) -> bool {
        let dx = (self.x - other.x).abs();
        let dy = (self.y - other.y).abs();
        let dz = (self.z - other.z).abs();
        (dx + dy + dz) == 1
    }

    fn max_coord(&self) -> i32 {
        (self.x).max(self.y).max(self.z)
    }

    fn min_coord(&self) -> i32 {
        (self.x).min(self.y).min(self.z)
    }

    fn neighbors(&self) -> Vec<Self> {
        let deltas = vec![
            (-1, 0, 0),
            (0, -1, 0),
            (0, 0, -1),
            (1, 0, 0),
            (0, 1, 0),
            (0, 0, 1),
        ];

        deltas
            .iter()
            .map(|(dx, dy, dz)| Self {
                x: self.x + dx,
                y: self.y + dy,
                z: self.z + dz,
            })
            .collect()
    }

    fn out_of_bounds(&self, lo: Self, hi: Self) -> bool {
        vec![
            self.x < lo.x,
            self.y < lo.y,
            self.z < lo.z,
            self.x > hi.x,
            self.y > hi.y,
            self.z > hi.z,
        ]
        .iter()
        .any(|b| *b)
    }
}
