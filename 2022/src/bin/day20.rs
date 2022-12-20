use std::collections::VecDeque;

const INPUT: &str = include_str!("../../input/day20.txt");

fn main() {
    let ciphertext = parse(INPUT);

    let mixed = mix(ciphertext);
    println!("{}", grove_hash(mixed));
}

fn parse(input: &str) -> Vec<i32> {
    aoc::lines(input).map(|s| s.parse().unwrap()).collect()
}

fn mix(ciphertext: Vec<i32>) -> Vec<i32> {
    let mut decrypter = Decrypter::new(&ciphertext);

    for (i, &n) in ciphertext.iter().enumerate() {
        decrypter.mv(i, n);
    }

    decrypter.read()
}

fn grove_hash(msg: Vec<i32>) -> i32 {
    let zero = msg.iter().position(|&n| n == 0).unwrap();
    let get = |i: usize| -> i32 { msg[(i + zero) % msg.len()] };

    get(1_000) + get(2_000) + get(3_000)
}

#[derive(Debug, Clone)]
struct Decrypter {
    message: Vec<i32>,
    len: usize,

    ptr: VecDeque<usize>,
}

impl Decrypter {
    fn new(ciphertext: &Vec<i32>) -> Self {
        Self {
            message: ciphertext.clone(),
            ptr: (0..ciphertext.len()).collect(),
            len: ciphertext.len(),
        }
    }

    fn read(&self) -> Vec<i32> {
        self.ptr.iter().map(|&p| self.message[p]).collect()
    }

    fn mv(&mut self, i: usize, n: i32) {
        let mut p = self.ptr.iter().position(|&p| p == i).unwrap();
        if n >= 0 {
            for _ in 1..=n {
                let q = (p + 1) % self.len;
                self.ptr.swap(p, q);

                if q == 0 {
                    // Swapped off the end, fix.
                    let extra = self.ptr.pop_back().unwrap();
                    self.ptr.push_front(extra);
                    p = 1;
                } else {
                    p = q;
                }
            }
        } else {
            for _ in 1..=(-n) {
                let q = (p + self.len - 1) % self.len;
                self.ptr.swap(p, q);

                if q == 0 {
                    // Swapped off the end, fix.
                    let extra = self.ptr.pop_front().unwrap();
                    self.ptr.push_back(extra);
                    p = self.len - 1;
                } else {
                    p = q
                }
            }
        }
    }
}
