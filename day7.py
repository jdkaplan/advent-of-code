from collections import namedtuple

Node = namedtuple('Node', ['name', 'disc', 'children'])

with open('input/day7') as f:
    puzzle_input = []
    for line in f.read().splitlines():
        children = []
        if '->' in line:
            line, rest = line.split('-> ')
            children = rest.split(', ')
        name, weight = line.split()
        weight = int(weight[1:-1])

        puzzle_input.append(Node(name, weight, tuple(children)))

def find_root(nodes):
    names = {node.name for node in nodes}
    supported = {child for node in nodes for child in node.children}
    return (names - supported).pop()

print(find_root(puzzle_input))

def memoized(f):
    cache = {}
    def _(*args):
        args = tuple(args)
        if args in cache:
            return cache[args]
        val = f(*args)
        cache[args] = val
        return val
    return _

def identical(iterable):
    return not iterable or len(set(iterable)) == 1

def counts(iterable):
    count = {}
    for i in iterable:
        count[i] = count.get(i, 0) + 1
    return count

def unbalanced(nodes):
    by_name = {node.name: node for node in nodes}
    root = by_name[find_root(nodes)]

    @memoized
    def weight(n):
        return n.disc + sum(weight(by_name[c]) for c in n.children)

    @memoized
    def is_balanced(n):
        return identical(weight(by_name[c]) for c in n.children)

    def walk(tree):
        if not is_balanced(tree):
            weights = [weight(by_name[c]) for c in tree.children]
            yield tree.name
            for n in (by_name[c] for c in tree.children):
                yield from walk(n)

    unbalanced = list(walk(root))[-1]
    children = [by_name[c] for c in by_name[unbalanced].children]
    weights = [weight(c) for c in children]
    weight_counts = counts(weights)
    odd_one = min(children, key=lambda n: weight_counts[weight(n)])
    majority = max(set(weights), key=lambda w: weight_counts[w])
    return majority - sum(weight(by_name[c]) for c in odd_one.children)

print(unbalanced(puzzle_input))
