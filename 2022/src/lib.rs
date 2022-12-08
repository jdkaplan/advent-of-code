pub fn split_lines(s: &str) -> Vec<&str> {
    s.trim_end().split('\n').collect()
}

pub fn split_words(s: &str) -> Vec<&str> {
    s.split(' ').collect()
}
