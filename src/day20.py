import sys
import pytest
from collections import Counter, defaultdict
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
    heappush(open_set, (0, start))  # (f_score, position)

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


def find_savings(m, start, end):
    _, path = astar(m, start, end)
    rows = len(m)
    cols = len(m[0])

    visited = set()  # don't double count a shortcut
    savings = defaultdict(int)
    lookup = {pt: i for i, pt in enumerate(path)}
    for pt, idx in lookup.items():
        y, x = pt
        # manhattan distance of 2
        # for part 2 this needs to be up to 20 and you need to
        # iterate through all the options of 2 to 20
        # maybe you should iterate through all points beforehand and
        # precalculate the distance from each point to each other pt
        # ie.
        # {
        #    pt1 -> pt2: 3, pt3: 4, pt5: 8
        #    pt2 -> pt3: 11, pt4: 20
        #    ptn -> ptn+1: ...
        # }
        # This is n^2 but only computed once...
        for dy, dx in [(-2, 0), (2, 0), (0, 2), (0, -2)]:
            ny, nx = y + dy, x + dx
            midx, midy = abs(y + ny) // 2, abs(x + nx) // 2
            if (
                0 <= nx < cols
                and 0 <= ny < rows
                and (ny, nx) in lookup
                and (midy, midx) not in visited
            ):
                visited.add((midy, midx))
                diff = abs(lookup[(ny, nx)] - idx) - 2
                if diff:
                    savings[diff] += 1
    return savings


def main():
    with open("data/input20.txt") as f:
        i = f.read()
    m, s, e = parse(i)
    savings = find_savings(m, s, e)
    print(f"part 1: {sum(n for i, n in savings.items() if i >= 100)}")


# def test_advent_part_one():
#     i = """###############
# #...#...#.....#
# #.#.#.#.#.###.#
# #S#...#.#.#...#
# #######.#.#.###
# #######.#.#...#
# #######.#.###.#
# ###..E#...#...#
# ###.#######.###
# #...###...#...#
# #.#####.#.###.#
# #.#...#.#.#...#
# #.#.#.#.#.#.###
# #...#...#...###
# ###############"""
#     m, s, e = parse(i)
#     savings = count_pico_savings(m, s, e)
#     assert savings[2] == 14
#     assert savings[4] == 14
#     assert savings[6] == 2
#     assert savings[8] == 4
#     assert savings[10] == 2
#     assert savings[12] == 3
#     assert savings[20] == 1
#     assert savings[36] == 1
#     assert savings[38] == 1
#     assert savings[40] == 1
#     assert savings[64] == 1


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


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvss", __file__])
    else:
        main()
