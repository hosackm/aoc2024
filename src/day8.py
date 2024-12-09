from collections import defaultdict, Counter
import pytest


def read_points_from_lines(matrix):
    char_to_point = defaultdict(set)
    for r, row in enumerate(matrix):
        for c, ch in enumerate(row.strip()):
            if ch == ".":
                continue
            char_to_point[ch].add((r, c))
    return dict(char_to_point)


def solve(matrix, part_two=False):
    matrix = [ln.strip() for ln in matrix.readlines()]

    def in_bounds(point):
        row, col = point
        return len(matrix) > row >= 0 and len(matrix[0]) > col >= 0

    nodes = set()
    ch_to_pts = read_points_from_lines(matrix)
    for pts in ch_to_pts.values():
        for i in pts:
            for j in pts:
                if i == j:
                    continue

                dx = j[1] - i[1]
                dy = j[0] - i[0]

                if part_two:
                    candidate = i
                    while in_bounds(candidate):
                        nodes.add(candidate)
                        candidate = (candidate[0] - dy, candidate[1] - dx)
                else:
                    candidate = (i[0] - dy, i[1] - dx)
                    if in_bounds(candidate):
                        nodes.add(candidate)

    return list(nodes)


def main():
    with open("data/input8.txt") as f:
        print(f"part 1: {len(solve(f))}")

    with open("data/input8.txt") as f:
        print(f"part 2: {len(solve(f, part_two=True))}")


@pytest.fixture
def test_lines():
    from textwrap import dedent
    from io import StringIO

    s = """......#....#
           ...#....0...
           ....#0....#.
           ..#....0....
           ....0....#..
           .#....A.....
           ...#........
           #......#....
           ........A...
           .........A..
           ..........#.
           ..........#."""
    return StringIO("\n".join(dedent(ln) for ln in s.split()))


def test_input_lines_correct(test_lines):
    c = Counter("".join(ln for ln in test_lines.readlines()))
    assert c["#"] == 13
    assert c["0"] == 4
    assert c["A"] == 3


def test_advent_example_part_one(test_lines):
    ch_to_pt = read_points_from_lines(test_lines)
    assert len(ch_to_pt["#"]) == 13
    assert len(ch_to_pt["0"]) == 4
    assert len(ch_to_pt["A"]) == 3
    (0, 6) in ch_to_pt["#"]
    (5, 6) in ch_to_pt["A"]
    (2, 5) in ch_to_pt["0"]


def test_solve(test_lines):
    nodes = solve(test_lines)
    assert len(nodes) == 33


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvs", __file__])
    else:
        main()
