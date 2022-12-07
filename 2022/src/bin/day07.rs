use std::{
    collections::HashMap,
    path::{Path, PathBuf},
};

use path_absolutize::Absolutize;

const INPUT: &str = include_str!("../../input/day07.txt");

fn main() {
    let mut cwd: PathBuf = "/".parse().unwrap(); // Because where else would we be?

    let mut fs: HashMap<PathBuf, Size> = HashMap::new();

    for block in parse(INPUT) {
        let cmdline: Vec<&str> = split_words(&block.cmd);

        let knowledge: Knowledge;
        (cwd, knowledge) = match cmdline[0] {
            "cd" => cd(&cwd, cmdline[1]),
            "ls" => ls(&cwd, block.out),
            other => panic!("{}", other),
        };

        for (path, size) in &knowledge {
            let Some(size) = size else { continue };
            let old = fs.insert(path.to_path_buf(), *size);

            assert!(old.is_none());
        }
    }

    let du = du(fs);

    let dirs = du.iter().collect::<Vec<_>>();

    let part1: u64 = dirs
        .iter()
        .cloned()
        .map(|(_path, size)| *size)
        .filter(|size| size <= &100_000)
        .sum();

    println!("Part 1: {}", part1);

    let total = 70_000_000;
    let needed = 30_000_000;

    let root: PathBuf = "/".parse().unwrap();
    let used = du.get(&root).unwrap();
    let unused = total - used;
    let to_free = needed - unused;

    let mut freeable = dirs
        .iter()
        .cloned()
        .map(|(_path, size)| *size)
        .filter(|size| size > &to_free)
        .collect::<Vec<u64>>();

    freeable.sort();

    let part2 = freeable[0];

    println!("Part 2: {}", part2);
}

fn du(fs: HashMap<PathBuf, Size>) -> HashMap<PathBuf, Size> {
    let mut dirs = HashMap::new();
    for (path, size) in fs {
        let mut dir = path;
        while dir.pop() {
            dirs.entry(dir.to_path_buf())
                .and_modify(|s| *s += size)
                .or_insert(size);
        }
    }
    dirs
}

type Size = u64;
type Knowledge = Vec<(PathBuf, Option<Size>)>;

fn cd(cwd: &Path, arg: &str) -> (PathBuf, Knowledge) {
    let cwd = cwd.join(arg);
    let cwd = cwd.absolutize().unwrap();
    (cwd.to_path_buf(), Default::default())
}

fn ls(cwd: &Path, output: String) -> (PathBuf, Knowledge) {
    let mut knowledge: Knowledge = vec![];

    for line in split_lines(&output) {
        let words = split_words(line);

        let size: Option<Size> = words[0].parse::<Size>().ok();
        let path = cwd.join(words[1]).to_path_buf();

        knowledge.push((path, size));
    }
    (cwd.into(), knowledge)
}

#[derive(Debug, Clone)]
struct Block {
    cmd: String,
    out: String,
}

fn parse(input: &str) -> Vec<Block> {
    let mut blocks = vec![];

    let lines = split_lines(input);

    let mut block: Option<Block> = None;

    for line in lines {
        if line.get(0..1) == Some("$") {
            if let Some(block) = block {
                blocks.push(block.clone());
            }

            block = Some(Block {
                cmd: line.get(("$ ".len())..).unwrap().to_string(),
                out: "".to_string(),
            });
        } else {
            let mut b = block.unwrap();
            b.out += line;
            b.out += "\n";
            block = Some(b);
        }
    }
    if let Some(block) = block {
        blocks.push(block);
    }

    blocks
}

fn split_lines(s: &str) -> Vec<&str> {
    s.trim_end().split('\n').collect()
}

fn split_words(s: &str) -> Vec<&str> {
    s.split(' ').collect()
}
