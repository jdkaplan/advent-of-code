use std::collections::VecDeque;

const INPUT: &str = include_str!("../../input/day25.txt");

fn main() {
    println!("{}", part1(INPUT));
}

fn part1(input: &str) -> String {
    let mut sum = 0;
    for line in input.lines() {
        let mut num: i64 = 0;
        for (i, digit) in line.chars().rev().enumerate() {
            let val = match digit {
                '=' => -2,
                '-' => -1,
                '0' => 0,
                '1' => 1,
                '2' => 2,
                other => panic!("{:?}", other),
            };

            num += 5_i64.pow(i.try_into().unwrap()) * val;
        }
        sum += num;
    }
    snafu(sum)
}

fn snafu(mut n: i64) -> String {
    assert!(n > 0);

    let mut digits: VecDeque<i64> = VecDeque::new();

    while n > 0 {
        match n % 5 {
            3 => digits.push_front(-2),
            4 => digits.push_front(-1),
            0 => digits.push_front(0),
            1 => digits.push_front(1),
            2 => digits.push_front(2),
            other => panic!("{:?}", other),
        };
        n -= digits[0];
        n /= 5;
    }

    digits
        .iter()
        .map(|digit| match digit {
            -2 => '=',
            -1 => '-',
            0 => '0',
            1 => '1',
            2 => '2',
            other => panic!("{:?}", other),
        })
        .collect()
}
