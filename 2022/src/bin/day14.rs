use std::collections::HashSet;

const INPUT: &str = include_str!("../../input/day14.txt");

fn main() {
    println!("{}", part1(INPUT));
}

fn part1(input: &str) -> usize {
    let paths = aoc::lines(input).map(Path::parse).collect();
    let wall = Wall::build(paths);

    wall.render();

    wall.rocks.len()
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
struct Point {
    x: i32,
    y: i32,
}

impl Point {
    fn new(x: i32, y: i32) -> Self {
        Self { x, y }
    }
}

impl std::fmt::Display for Point {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "({}, {})", self.x, self.y)
    }
}

#[derive(Debug, Clone)]
struct Path(Vec<Point>);

impl Path {
    fn parse(line: &str) -> Self {
        let waypoints = line
            .split(" -> ")
            .map(|point| {
                let parts: Vec<&str> = point.split(',').collect();
                let x: i32 = parts[0].parse().unwrap();
                let y: i32 = parts[1].parse().unwrap();
                Point { x, y }
            })
            .collect();

        Self(waypoints)
    }

    fn segments(&self) -> Vec<Segment> {
        let points = &self.0;
        (1..points.len())
            .map(|i| Segment {
                from: points[i - 1],
                to: points[i],
            })
            .collect()
    }
}

#[derive(Debug, Copy, Clone)]
struct Segment {
    from: Point,
    to: Point,
}

impl Segment {
    fn tween(&self) -> Vec<Point> {
        if self.from.x == self.to.x {
            let x = self.from.x;
            let (y_min, y_max) = minmax(self.from.y, self.to.y);
            (y_min..=y_max).map(|y| Point { x, y }).collect()
        } else if self.from.y == self.to.y {
            let y = self.from.y;
            let (x_min, x_max) = minmax(self.from.x, self.to.x);
            (x_min..=x_max).map(|x| Point { x, y }).collect()
        } else {
            panic!("{:?} off-axis from {:?}", self.from, self.to)
        }
    }
}

struct Wall {
    rocks: HashSet<Point>,
}

impl Wall {
    fn build(paths: Vec<Path>) -> Self {
        let mut rocks = HashSet::new();

        for path in paths {
            for segment in path.segments() {
                dbg!(segment);
                for point in segment.tween() {
                    rocks.insert(point);
                    dbg!(point);
                }
            }
        }

        Self { rocks }
    }

    fn render(&self) {
        let lo = self
            .rocks
            .iter()
            .cloned()
            .reduce(|lo, p| Point::new(lo.x.min(p.x), lo.y.min(p.y)))
            .unwrap();

        let hi = self
            .rocks
            .iter()
            .cloned()
            .reduce(|hi, p| Point::new(hi.x.max(p.x), hi.y.max(p.y)))
            .unwrap();

        let chr = move |x: i32, y: i32| -> char {
            if self.rocks.contains(&Point { x, y }) {
                '#'
            } else {
                '.'
            }
        };

        println!("lo: {}, hi: {}", lo, hi);

        // Screen coordinates, yay!
        for y in lo.y..=hi.y {
            for x in lo.x..=hi.x {
                print!("{}", chr(x, y));
            }
            println!();
        }
        println!();
    }
}

fn minmax<T: PartialOrd>(a: T, b: T) -> (T, T) {
    if a < b {
        (a, b)
    } else {
        (b, a)
    }
}
