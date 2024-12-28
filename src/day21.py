import sys
import pytest
from collections import deque, defaultdict
from functools import cache


def get_neighbors(previous):
    return {
        "<": [(0, -1, "<"), (1, 0, "v"), (-1, 0, "^"), (0, 1, ">")],
        "^": [(-1, 0, "^"), (1, 0, "v"), (0, 1, ">"), (0, -1, "<")],
        "v": [(1, 0, "v"), (-1, 0, "^"), (0, 1, ">"), (0, -1, "<")],
        ">": [(0, 1, ">"), (1, 0, "v"), (-1, 0, "^"), (0, -1, "<")],
    }[previous or "<"]


def all_shortest_paths(src, dst, rows, cols, gap):
    shortest = None
    paths = []
    path = ""
    direction = ""
    queue = deque([(src, path, direction)])
    visited = set()
    while queue:
        node, path, previous_direction = queue.popleft()
        if node in visited:
            continue

        if shortest is not None and len(path) > shortest:
            continue

        if node == dst:
            if shortest is None:
                shortest = len(path)

            if len(path) == shortest:
                paths.append(path)

        for dy, dx, ch in get_neighbors(previous_direction):
            y, x = node
            ny, nx = y + dy, x + dx
            if 0 <= ny < rows and 0 <= nx < cols and (ny, nx) != gap:
                queue.append(((ny, nx), path + ch, ch))

    return paths


@cache
def build_keypad_mappings():
    gap = (3, 0)
    keypad_digits = {
        "A": (3, 2),
        "0": (3, 1),
        "1": (2, 0),
        "2": (2, 1),
        "3": (2, 2),
        "4": (1, 0),
        "5": (1, 1),
        "6": (1, 2),
        "7": (0, 0),
        "8": (0, 1),
        "9": (0, 2),
    }
    keypad_mapping = defaultdict(dict)

    for d1, dv1 in keypad_digits.items():
        for d2, dv2 in keypad_digits.items():
            if d1 == d2:
                keypad_mapping[d1][d2] = [""]
                continue
            keypad_mapping[d1][d2] = all_shortest_paths(dv1, dv2, 4, 3, gap)

    return keypad_mapping


def build_dpad_mappings():
    gap = (0, 0)
    dpad_digits = {
        "^": (0, 1),
        "A": (0, 2),
        "<": (1, 0),
        "v": (1, 1),
        ">": (1, 2),
    }
    dpad_mapping = defaultdict(dict)

    for d1, dv1 in dpad_digits.items():
        for d2, dv2 in dpad_digits.items():
            if d1 == d2:
                dpad_mapping[d1][d2] = [""]
                continue
            dpad_mapping[d1][d2] = all_shortest_paths(dv1, dv2, 2, 3, gap)

    return dpad_mapping


def main():
    with open("data/input21.txt") as f:
        sequences = [ln.strip() for ln in f if ln.strip()]

    print(f"part 1: {calculate(sequences)}")
    print(f"part 2: {calculate(sequences, n=25)}")


def calculate(sequences, n=2):
    recfunc = build_cached(
        build_keypad_mappings(),
        build_dpad_mappings(),
    )

    total = 0
    for seq in sequences:
        length = recfunc(seq, 0, n)
        total += int(seq[:3]) * length
    return total


def build_cached(kmap, dmap):
    num_kpads = 1

    @cache
    def cached(code, current=0, num_dpads=2):
        if current == num_dpads + num_kpads:
            return len(code)

        total = 0
        map = kmap if current == 0 else dmap

        src = "A"
        for dst in code:
            min_seq = [cached(p + "A", current + 1, num_dpads) for p in map[src][dst]]
            total += min(min_seq) if min_seq else 1
            src = dst
        return total

    return cached


def test_part_one_example():
    sequences = [
        "029A",
        "980A",
        "179A",
        "456A",
        "379A",
    ]
    expected = 126384
    assert calculate(sequences) == expected


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvvs", __file__])
    else:
        main()
