import sys
import pytest


def can_fit(lock, key):
    return all((lock[i] + key[i]) < 6 for i in range(len(lock)))


def count(lines, is_lock=True):
    this_count = [0] * 5

    if not is_lock:
        lines = reversed(lines)

    for j, ln in enumerate(lines):
        if j == 0:  # skip the first line
            continue

        for i, ch in enumerate(ln):
            this_count[i] += 1 if ch == "#" else 0

    return tuple(c for c in this_count)


def parse(lines):
    groups = [g.strip() for g in lines.strip().split("\n\n")]
    keys = []
    locks = []

    for group in groups:
        is_lock = group[0][0] == "#"
        c = count(group.split("\n"), is_lock=is_lock)
        if is_lock:
            locks.append(c)
        else:
            keys.append(c)

    return locks, keys


def main():
    with open("data/input25.txt") as f:
        locks, keys = parse(f.read())

    total = sum(can_fit(lock, key) for lock in locks for key in keys)
    print(f"part 1: {total}")


def test_count():
    s = """#####
.####
.####
.####
.#.#.
.#...
....."""
    assert count(s.split("\n"), is_lock=True) == (0, 5, 3, 4, 3)

    s = """.....
#....
#....
#...#
#.#.#
#.###
#####"""
    assert count(s.split("\n"), is_lock=False) == (5, 0, 2, 1, 3)


def test_can_fit():
    assert not can_fit((0, 5, 3, 4, 3), (5, 0, 2, 1, 3))
    assert not can_fit((0, 5, 3, 4, 3), (4, 3, 4, 0, 2))
    assert can_fit((0, 5, 3, 4, 3), (3, 0, 2, 0, 1))
    assert not can_fit((1, 2, 0, 5, 3), (5, 0, 2, 1, 3))
    assert can_fit((1, 2, 0, 5, 3), (4, 3, 4, 0, 2))
    assert can_fit((1, 2, 0, 5, 3), (3, 0, 2, 0, 1))


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvvs", __file__])
    else:
        main()
