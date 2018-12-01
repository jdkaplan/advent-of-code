with open('input/day4') as f:
    puzzle_input = f.read().splitlines()

def is_valid(passphrase):
    words = passphrase.split()
    return len(words) == len(set(words))

def validity_count(passphrases):
    return len({p for p in passphrases if is_valid(p)})

class Counter:
    def __init__(self, iterable):
        self._counts = {}
        for i in iterable:
            self._counts[i] = self._counts.get(i, 0) + 1

    def __eq__(self, other):
        if self._counts.keys() != other._counts.keys():
            return False
        for k in self._counts.keys():
            if self._counts[k] != other._counts[k]:
                return False
        return True

def are_anagrams(w1, w2):
    return Counter(w1) == Counter(w2)

def pairs(l):
    for i, e1 in enumerate(l):
        for e2 in l[i+1:]:
            yield (e1, e2)

def is_valid2(passphrase):
    return all(not are_anagrams(w1, w2) for w1, w2 in pairs(passphrase.split()))

def validity_count2(passphrases):
    return len({p for p in passphrases if is_valid2(p)})

print(validity_count(puzzle_input))
print(validity_count2(puzzle_input))
