import pytest
import sys

from collections import defaultdict


def find_combos_dp(pattern, towels):
    d = defaultdict(int)
    d[""] = 1  # empty is always possible for first iteration

    # dynamic programming table
    for i in range(1, len(pattern) + 1):
        partial_pattern = pattern[:i]
        for t in towels:
            # only consider towels that can be placed at end
            if not partial_pattern.endswith(t):
                continue

            # if we place this towel at the end, we're
            # basing it on the number of patterns we can
            # make with the pattern minus this towel
            # ie. d['abc'] = d['ab'] + towel_c
            last_chunk = partial_pattern[: -len(t)]
            d[partial_pattern] += d.get(last_chunk, 0)

    return d[pattern]


def is_possible(pattern, towels):
    """
    Original solution but ground to a halt for part two.
    So I searched for a dynamic programming solution.
    """
    partials = set([t for t in towels if pattern.startswith(t)])

    while partials:
        this_turn = set()
        for towel in towels:
            for partial in partials:
                candidate = partial + towel
                if pattern == candidate:
                    return True
                if pattern.startswith(candidate):
                    this_turn.add(candidate)
        partials = this_turn
    return False


def count_num_possible(patterns, towels):
    return sum(find_combos_dp(p, towels) > 0 for p in patterns)


def count_combinations(patterns, towels):
    return sum(find_combos_dp(p, towels) for p in patterns)


def main():
    with open("data/input19.txt") as f:
        data = f.read()

    towels = data.split("\n\n")[0].strip().split(", ")
    patterns = data.split("\n\n")[1].strip().split("\n")

    print(f"part 1: {count_num_possible(patterns, towels)}")
    print(f"part 2: {count_combinations(patterns, towels)}")


def test_example_part_one():
    patterns = ["brwrr", "bggr", "gbbr", "rrbgbr", "ubwu", "bwurrg", "brgr", "bbrgwb"]
    towels = ["r", "wr", "b", "g", "bwu", "rb", "gb", "br"]
    assert count_num_possible(patterns, towels) == 6


def test_example_part_two():
    patterns = ["brwrr", "bggr", "gbbr", "rrbgbr", "ubwu", "bwurrg", "brgr", "bbrgwb"]
    towels = ["r", "wr", "b", "g", "bwu", "rb", "gb", "br"]
    assert count_combinations(patterns, towels) == 16


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvvs", __file__])
    else:
        main()
