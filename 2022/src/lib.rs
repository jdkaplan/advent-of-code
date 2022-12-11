use std::str::Split;

pub fn lines(s: &str) -> Split<char> {
    s.trim_end().split('\n')
}

pub fn words(s: &str) -> Split<char> {
    s.split(' ')
}

pub fn blocks(s: &str) -> Split<&str> {
    s.split("\n\n")
}
