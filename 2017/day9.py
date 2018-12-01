import enum

@enum.unique
class Token(enum.Enum):
    GroupStart = '{'
    GroupEnd = '}'
    GarbageStart = '<'
    GarbageEnd = '>'
    Cancel = '!'

def log(f):
    def _(*args):
        ret = f(*args)
        print(*args, '->', ret)
        return ret
    return _

def tokenize(stream):
    tokens = {t.value: t for t in Token}
    return [tokens[c] for c in stream if c in tokens]

def cancel(tokens):
    stack = []
    i = 0
    cancellations = 0
    while i < len(tokens):
        t = tokens[i]
        if t == Token.Cancel:
            cancellations += 1
            i += 2
            continue
        stack.append(t)
        i += 1

    assert len(tokens) == len(stack) + 2*cancellations

    return stack

def clean(tokens):
    stack = []
    i = 0
    while i < len(tokens):
        if tokens[i] == Token.GarbageStart:
            while tokens[i] != Token.GarbageEnd:
                i += 1
            i += 1
            continue
        print('PUSH:', i, tokens[i])
        stack.append(tokens[i])
        i += 1
    return stack

class Group:
    def __init__(self):
        self.children = []

    def append(self, child):
        self.children.append(child)

    def __repr__(self):
        return '{{}}'.format(''.join(repr(c) for c in self.children))

    __str__ = __repr__

def parse(tokens):
    stack = []
    outer = Group()
    last = None
    tokens = list(clean(cancel(tokens)))
    print(len([t for t in tokens if t == Token.GroupStart]), len([t for t in tokens if t == Token.GroupEnd]))
    assert len([t for t in tokens if t == Token.GroupStart]) == len([t for t in tokens if t == Token.GroupEnd])
    for t in tokens:
        if t == Token.GroupStart:
            g = Group()
            if stack:
                stack[-1].append(g)
            stack.append(g)
        elif t == Token.GroupEnd:
            last = stack.pop(-1)
    return last

def score(group, depth=1):
    return depth + sum(score(c, depth+1) for c in group.children)

def solve(stream):
    stuff = parse(tokenize(stream))
    if stuff is None: return 0
    return score(stuff)

with open('input/day9') as f:
    puzzle_input = f.read()

#  print(solve('<{o"i!a,<{i<a>'))
print(solve(puzzle_input))
