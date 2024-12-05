from collections import defaultdict
from typing import Tuple


class BeforeTracker:
    def __init__(self, mappings):
        self.before_map = defaultdict(set)
        for first, after in mappings:
            self.before_map[first].add(after)

    def check_swap(self, nums: list[str], swap: bool = False) -> Tuple[list[str], bool]:
        """
        Check if the given numbers following the ordering rules in self.before_map.
        If swap is True, then perform a swap of numbers that are out of order.

        Returns:
            Tuple[list[str], bool]: the corrected number list and if correction was required.
        """
        correction_required = False
        for i in range(len(nums) - 1):
            for j in range(i + 1, len(nums)):
                if nums[i] in self.before_map[nums[j]]:
                    correction_required = True
                    if swap:
                        nums[i], nums[j] = nums[j], nums[i]
        return nums, correction_required


def get_mappings_and_tests(data):
    mappings = []
    tests = []
    for ln in data:
        if "|" in ln:
            mappings.append(ln.strip().split("|"))
        if "," in ln:
            tests.append(ln.strip().split(","))
    return mappings, tests


def test_advent_example():
    from io import StringIO

    test_input = StringIO("""47|53
    97|13
    97|61
    97|47
    75|29
    61|13
    75|53
    29|13
    97|29
    53|29
    61|53
    97|53
    61|29
    47|13
    75|47
    97|75
    47|61
    75|61
    47|29
    75|13
    53|13

    75,47,61,53,29
    97,61,53,29,13
    75,29,13
    75,97,47,61,53
    61,13,29
    97,13,75,29,47""")
    mappings, tests = get_mappings_and_tests(test_input)
    b = BeforeTracker(mappings)
    expected = (True, True, True, False, False, False)

    # Part 1
    results = [b.check_swap(t) for t in tests]
    for r, e in zip(results, expected):
        _, is_corrected = r
        assert is_corrected != e

    total = 0
    for r in results:
        nums, is_corrected = r
        if not is_corrected:
            print(f"adding {r}")
            total += int(nums[len(nums) // 2])
    assert total == 143

    # Part 2
    results = [b.check_swap(t, True) for t in tests]
    for r, e in zip(results, expected):
        _, is_corrected = r
        assert is_corrected != e

    total = 0
    for r in results:
        nums, is_corrected = r
        if is_corrected:
            print(f"adding {r}")
            total += int(nums[len(nums) // 2])
    assert total == 123


def main():
    mappings = []
    tests = []

    with open("data/input5.txt") as f:
        for ln in f:
            if "|" in ln:
                mappings.append(ln.strip().split("|"))
            if "," in ln:
                tests.append(ln.strip().split(","))

    b = BeforeTracker(mappings)
    total = 0
    for t in tests[:]:
        _, corrected = b.check_swap(t, False)
        if not corrected:
            total += int(t[len(t) // 2])
    print(f"part 1: {total}")

    total = 0
    for t in tests[:]:
        output, corrected = b.check_swap(t, True)
        if corrected:
            total += int(output[len(output) // 2])
    print(f"part 2: {total}")


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "test":
        import pytest

        pytest.main(["-xv", __file__])
    else:
        main()
