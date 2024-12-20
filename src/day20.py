import sys
import pytest
from collections import defaultdict
from heapq import heappop, heappush
from math import inf


def reconstruct(d, n, start, end):
    path = []
    while n in d:
        path.append(n)
        n = d[n]
    path.append(start)
    return list(reversed(path))


def astar(grid, start, end):
    def manhattan(a, b):
        return abs(a[0] - b[0]) + abs(a[1] - b[1])

    rows, cols = len(grid), len(grid[0])
    open_set = []
    heappush(open_set, (0, start))

    came_from = {}
    g_score = {start: 0}
    f_score = {start: manhattan(start, end)}

    while open_set:
        score, current = heappop(open_set)

        if current == end:
            return (score, reconstruct(came_from, current, start, end))

        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:  # N, S, W, E
            neighbor = (current[0] + dx, current[1] + dy)
            ny, nx = neighbor
            if 0 <= ny < rows and 0 <= nx < cols:
                if grid[ny][nx] == "#":
                    continue

                tentative_g_score = g_score[current] + 1

                if neighbor not in g_score or tentative_g_score < g_score[neighbor]:
                    came_from[neighbor] = current
                    g_score[neighbor] = tentative_g_score
                    f_score[neighbor] = tentative_g_score + manhattan(neighbor, end)
                    heappush(open_set, (f_score[neighbor], neighbor))

    return inf, []


def parse(s):
    m = []
    start = None
    for r, row in enumerate(s.split("\n")):
        mr = []
        for c, ch in enumerate(row):
            if ch == "S":
                start = (r, c)
            elif ch == "E":
                end = (r, c)
            mr.append(ch)
        m.append(mr)
    return m, start, end


def find_savings(m, start, end, max_distance=2):
    _, path = astar(m, start, end)
    visited = set()
    savings = defaultdict(int)
    lookup = {pt: i for i, pt in enumerate(path)}

    possible_shortcuts = []
    for pt in lookup:
        for pt2 in lookup:
            if pt == pt2:
                continue
            dist = abs(pt2[0] - pt[0]) + abs(pt2[1] - pt[1])
            if 1 < dist <= max_distance:
                possible_shortcuts.append((pt, pt2, dist))

    for pta, ptb, dist in possible_shortcuts:
        if (ptb, pta) in visited:
            continue

        visited.add((pta, ptb))
        diff = abs(lookup[ptb] - lookup[pta]) - dist
        if diff:
            savings[diff] += 1

    return savings


def main():
    with open("data/input20.txt") as f:
        i = f.read()
    m, s, e = parse(i)
    savings = find_savings(m, s, e)
    print(f"part 1: {sum(n for i, n in savings.items() if i >= 100)}")
    savings = find_savings(m, s, e, max_distance=20)
    print(f"part 2: {sum(n for i, n in savings.items() if i >= 100)}")


def test_advent_part_one():
    i = """###############
#...#...#.....#
#.#.#.#.#.###.#
#S#...#.#.#...#
#######.#.#.###
#######.#.#...#
#######.#.###.#
###..E#...#...#
###.#######.###
#...###...#...#
#.#####.#.###.#
#.#...#.#.#...#
#.#.#.#.#.#.###
#...#...#...###
###############"""
    m, s, e = parse(i)
    savings = find_savings(m, s, e)
    assert savings[2] == 14
    assert savings[4] == 14
    assert savings[6] == 2
    assert savings[8] == 4
    assert savings[10] == 2
    assert savings[12] == 3
    assert savings[20] == 1
    assert savings[36] == 1
    assert savings[38] == 1
    assert savings[40] == 1
    assert savings[64] == 1
    assert astar(m, s, e)[0] == 84


def test_advent_part_two():
    i = """###############
#...#...#.....#
#.#.#.#.#.###.#
#S#...#.#.#...#
#######.#.#.###
#######.#.#...#
#######.#.###.#
###..E#...#...#
###.#######.###
#...###...#...#
#.#####.#.###.#
#.#...#.#.#...#
#.#.#.#.#.#.###
#...#...#...###
###############"""
    m, s, e = parse(i)
    savings = find_savings(m, s, e, max_distance=20)
    assert savings[50] == 32
    assert savings[52] == 31
    assert savings[54] == 29
    assert savings[56] == 39
    assert savings[58] == 25
    assert savings[60] == 23
    assert savings[62] == 20
    assert savings[64] == 19
    assert savings[66] == 12
    assert savings[68] == 14
    assert savings[70] == 12
    assert savings[72] == 22
    assert savings[74] == 4
    assert savings[76] == 3


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvss", __file__])
    else:
        main()
