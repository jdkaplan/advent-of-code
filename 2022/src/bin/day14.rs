use std::collections::HashSet;

const INPUT: &str = include_str!("../../input/day14.txt");

fn main() {
    let paths = aoc::lines(INPUT).map(Path::parse).collect();
    let wall = Wall::build(paths);

    println!("{}", part1(wall.clone()));
    println!("{}", part2(wall));
}

fn part1(mut wall: Wall) -> usize {
    while wall.add_sand_1().is_some() {}

    wall.render();
    wall.sand.len()
}

fn part2(mut wall: Wall) -> usize {
    while let Some(_pos) = wall.add_sand_2() {}

    wall.render();
    wall.sand.len()
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

#[derive(Debug, Clone)]
struct Wall {
    rocks: HashSet<Point>,
    sand: HashSet<Point>,
    y_abyss: i32,
    y_floor: i32,
}

impl Wall {
    const SAND_SOURCE: Point = Point { x: 500, y: 0 };

    fn build(paths: Vec<Path>) -> Self {
        let sand = HashSet::new();
        let mut rocks = HashSet::new();
        let mut y_abyss = 0i32;

        for path in paths {
            for segment in path.segments() {
                for point in segment.tween() {
                    rocks.insert(point);
                    y_abyss = y_abyss.max(point.y);
                }
            }
        }

        let y_floor = y_abyss + 2;

        Self {
            rocks,
            sand,
            y_abyss,
            y_floor,
        }
    }

    fn render(&self) {
        let (lo, hi) = self.rocks.iter().chain(self.sand.iter()).fold(
            (Wall::SAND_SOURCE, Wall::SAND_SOURCE),
            |(lo, hi), Point { x, y }| {
                (
                    Point::new(lo.x.min(*x), lo.y.min(*y)),
                    Point::new(hi.x.max(*x), hi.y.max(*y)),
                )
            },
        );

        let chr = move |x: i32, y: i32| -> char {
            let p = Point { x, y };
            if p == Wall::SAND_SOURCE {
                '+'
            } else if self.rocks.contains(&p) {
                '#'
            } else if self.sand.contains(&p) {
                'o'
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

impl Point {
    fn mv(&self, dx: i32, dy: i32) -> Point {
        Point {
            x: self.x + dx,
            y: self.y + dy,
        }
    }
}

impl Wall {
    fn filled(&self, p: &Point) -> bool {
        p == &Wall::SAND_SOURCE
            || self.rocks.contains(p)
            || self.sand.contains(p)
            || p.y >= self.y_floor
    }

    fn empty(&self, p: &Point) -> bool {
        !self.filled(p)
    }

    fn add_sand_1(&mut self) -> Option<Point> {
        let pos = self.drop_sand(self.y_abyss);

        if pos.y < self.y_abyss {
            self.sand.insert(pos);
            Some(pos)
        } else {
            None
        }
    }

    fn add_sand_2(&mut self) -> Option<Point> {
        let pos = self.drop_sand(self.y_floor);

        if self.sand.insert(pos) {
            Some(pos)
        } else {
            None
        }
    }

    fn drop_sand(&self, y_max: i32) -> Point {
        let mut pos = Wall::SAND_SOURCE;

        'tick: while pos.y <= y_max {
            let candidates = vec![
                pos.mv(0, 1),  // down
                pos.mv(-1, 1), // down-left
                pos.mv(1, 1),  // down-right
            ];

            for next in candidates {
                if self.empty(&next) {
                    pos = next;
                    continue 'tick;
                }
            }

            // Stuck!
            break 'tick;
        }

        pos
    }
}

fn minmax<T: PartialOrd>(a: T, b: T) -> (T, T) {
    if a < b {
        (a, b)
    } else {
        (b, a)
    }
}
