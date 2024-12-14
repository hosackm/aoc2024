import re
import sys
import pytest


PART_TWO_OFFSET = 10000000000000


def solve(nums, part_two=False):
    ax, ay = nums[:2]
    bx, by = nums[2:4]
    gx, gy = nums[4:6]
    if part_two:
        gx += PART_TWO_OFFSET
        gy += PART_TWO_OFFSET

    # both equations have a common divisor
    divisor = bx * ay - by * ax
    a = int((bx * gy - by * gx) / divisor)
    b = int((ay * gx - ax * gy) / divisor)

    if (a * ax + b * bx == gx) and (a * ay + b * by == gy):
        return 3 * a + b
    return 0


def parse_input(s):
    n = 3
    nums = []
    lines = [ln for ln in s.split("\n") if ln]
    for i in range(len(lines) // n):
        nums.append(
            [int(n) for n in re.findall(r"(\d+)", "".join(lines[n * i : n * i + n]))]
        )

    return nums


def main():
    with open("data/input13.txt") as f:
        nums = parse_input(f.read().strip())
        answers = [solve(n) for n in nums]
        print(f"part 1: {sum(answers)}")
    with open("data/input13.txt") as f:
        nums = parse_input(f.read().strip())
        answers = [solve(n, part_two=True) for n in nums]
        print(f"part 2: {sum(answers)}")


def test_advent_of_code_example():
    s = """
Button A: X+94, Y+34
Button B: X+22, Y+67
Prize: X=8400, Y=5400

Button A: X+26, Y+66
Button B: X+67, Y+21
Prize: X=12748, Y=12176

Button A: X+17, Y+86
Button B: X+84, Y+37
Prize: X=7870, Y=6450

Button A: X+69, Y+23
Button B: X+27, Y+71
Prize: X=18641, Y=10279""".strip()
    nums = parse_input(s)
    answers = [solve(n) for n in nums]
    assert answers[0] == 280
    assert answers[1] == 0
    assert answers[2] == 200
    assert answers[3] == 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvvs", __file__])
    else:
        main()
