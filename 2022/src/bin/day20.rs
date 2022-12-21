use std::collections::VecDeque;

const INPUT: &str = include_str!("../../input/day20.txt");

fn main() {
    let ciphertext = parse(INPUT);

    println!("Part 1: {}", part1(ciphertext.clone()));
    println!("Part 2: {}", part2(ciphertext));
}

fn parse(input: &str) -> Vec<i64> {
    aoc::lines(input).map(|s| s.parse().unwrap()).collect()
}

fn part1(ciphertext: Vec<i64>) -> i64 {
    let mixed = mix(ciphertext, 1);
    grove_hash(mixed)
}

fn part2(ciphertext: Vec<i64>) -> i64 {
    let decryption_key: i64 = 811589153;
    let keyed: Vec<i64> = ciphertext.iter().map(|&n| n * decryption_key).collect();

    let mixed = mix(keyed, 10);
    grove_hash(mixed)
}

fn mix(ciphertext: Vec<i64>, times: usize) -> Vec<i64> {
    let mut decrypter = Decrypter::new(&ciphertext);

    for _ in 0..times {
        for (i, &n) in ciphertext.iter().enumerate() {
            decrypter.mv(i, n);
        }
    }

    decrypter.read()
}

fn grove_hash(msg: Vec<i64>) -> i64 {
    let zero = msg.iter().position(|&n| n == 0).unwrap();
    let get = |i: usize| -> i64 { msg[(i + zero) % msg.len()] };

    get(1_000) + get(2_000) + get(3_000)
}

#[derive(Debug, Clone)]
struct Decrypter {
    message: Vec<i64>,
    ptr: VecDeque<usize>,
    len: usize,
    ilen: i64,
}

impl Decrypter {
    fn new(ciphertext: &Vec<i64>) -> Self {
        let len = ciphertext.len();
        Self {
            message: ciphertext.clone(),
            ptr: (0..len).collect(),
            len,
            ilen: len.try_into().unwrap(),
        }
    }

    fn read(&self) -> Vec<i64> {
        self.ptr.iter().map(|&p| self.message[p]).collect()
    }

    fn mv(&mut self, i: usize, n: i64) {
        let p = self.ptr.iter().position(|&p| p == i).unwrap();

        if n >= 0 {
            // [a, b, c, i, x, y, z]
            self.ptr.rotate_left(p);
            // [i, x, y, z, a, b, c]

            let m = self.ptr.pop_front().unwrap();
            // i | [x, y, z, a, b, c]
            assert_eq!(i, m);

            let n = delta(n, self.ilen);
            self.ptr.rotate_left(n);
            self.ptr.push_front(m);
        } else {
            // [a, b, c, i, x, y, z]
            self.ptr.rotate_right(self.len - p - 1);
            // [x, y, z, a, b, c, i]

            let m = self.ptr.pop_back().unwrap();
            // [x, y, z, a, b, c] | i
            assert_eq!(i, m);

            let n = delta(n, self.ilen);
            self.ptr.rotate_right(n);
            self.ptr.push_back(m);
        }
    }
}

fn delta(n: i64, len: i64) -> usize {
    let n = n.abs();
    // It takes n-1 swaps to get back to where we started, so treat these as extra "hops" over the
    // original position.
    let skips = n / (len - 1);
    let extra = n % len;
    ((skips + extra) % len).try_into().unwrap()
}
