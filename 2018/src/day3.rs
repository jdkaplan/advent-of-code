use std::collections::HashMap;
const INPUT: &str = include_str!("input/day3.txt");

struct Rectangle {
    id: String,
    x: u32,
    y: u32,
    w: u32,
    h: u32,
}

fn parse_input(input: &str) -> Vec<Rectangle> {
    let mut rects = Vec::new();
    for line in str::lines(input) {
        // #id @ x,y: wxh
        let mut tokens = Vec::new();
        let mut tok = "".to_string();
        for c in line.chars() {
            match c {
                ' ' | ',' | 'x' | '@' => {
                    if !tok.is_empty() {
                        tokens.push(tok);
                    }
                    tok = "".to_string();
                }
                '#' | ':' => (),
                _ => tok.push(c),
            }
        }
        if !tok.is_empty() {
            tokens.push(tok);
        }

        let id = tokens[0].to_string();
        let x = tokens[1].parse::<u32>().unwrap();
        let y = tokens[2].parse::<u32>().unwrap();
        let w = tokens[3].parse::<u32>().unwrap();
        let h = tokens[4].parse::<u32>().unwrap();
        rects.push(Rectangle {
            id: id,
            x: x,
            y: y,
            w: w,
            h: h,
        })
    }
    rects
}

pub fn part1() -> u32 {
    let mut squares = HashMap::new();
    for r in parse_input(INPUT) {
        for x in r.x..(r.x + r.w) {
            for y in r.y..(r.y + r.h) {
                let mut count = squares.entry((x, y)).or_insert(0);
                *count += 1;
            }
        }
    }
    let mut count = 0;
    for (_, layers) in squares {
        if layers > 1 {
            count += 1;
        }
    }
    count
}

fn uncovered(grid: &HashMap<(u32, u32), u32>, r: &Rectangle) -> bool {
    for x in r.x..(r.x + r.w) {
        for y in r.y..(r.y + r.h) {
            match grid.get(&(x, y)) {
                Some(1) => {}
                _ => return false,
            }
        }
    }
    true
}

pub fn part2() -> String {
    let mut squares = HashMap::new();
    let rects = parse_input(INPUT);
    for r in &rects {
        for x in r.x..(r.x + r.w) {
            for y in r.y..(r.y + r.h) {
                let mut count = squares.entry((x, y)).or_insert(0);
                *count += 1;
            }
        }
    }
    for r in &rects {
        if uncovered(&squares, r) {
            return r.id.to_owned();
        }
    }
    panic!("No solution!")
}
