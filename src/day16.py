import pytest
import sys
from math import inf
from heapq import heappush, heappop

DIRS = {
    "N": (-1, 0),
    "E": (0, 1),
    "S": (1, 0),
    "W": (0, -1),
}
ORDER = list(DIRS.keys())


def find_paths(maze, start, end):
    visited = {}
    q = []
    highscore = inf
    paths = []

    heappush(q, (0, start, "E", ""))
    while q:
        score, pos, d, path = heappop(q)
        if score > highscore:
            break
        if (pos, d) in visited and visited[(pos, d)] < score:
            continue
        visited[(pos, d)] = score
        if pos == end:
            highscore = score
            paths.append(path)

        posy, posx = pos
        dy, dx = DIRS[d]
        if maze[posy + dy][posx + dx] != "#":
            heappush(q, (score + 1, (posy + dy, posx + dx), d, path + "F"))

        next_direction = ORDER[(ORDER.index(d) + 1) % len(ORDER)]
        heappush(q, (score + 1000, pos, next_direction, path + "R"))
        next_direction = ORDER[(ORDER.index(d) - 1) % len(ORDER)]
        heappush(q, (score + 1000, pos, next_direction, path + "L"))

    return paths, highscore


def matrix(lines):
    m = []
    start = None
    end = None
    for r, line in enumerate(lines):
        row = []
        for c, ch in enumerate(line):
            if ch == "E":
                end = (r, c)
            if ch == "S":
                start = (r, c)
            row.append(ch)
        m.append(row)
    return m, start, end


def count_tiles(paths, start):
    tiles = set([start])
    for path in paths:
        posx, posy = start
        direction = "E"
        for d in path:
            if d == "F":
                dx, dy = DIRS[direction]
                posx = posx + dx
                posy = posy + dy
                tiles.add((posx, posy))
            if d == "L":
                direction = ORDER[(ORDER.index(direction) - 1) % len(ORDER)]
            elif d == "R":
                direction = ORDER[(ORDER.index(direction) + 1) % len(ORDER)]
    return tiles


def main():
    with open("data/input16.txt") as f:
        lines = f.read().split("\n")
        m, start, end = matrix(lines)

    paths, score = find_paths(m, start, end)
    print(f"part 1: {score}")

    print(f"part 2: {len(count_tiles(paths, start))}")


def test_advent_part_one_examples():
    s = """###############
#.......#....E#
#.#.###.#.###.#
#.....#.#...#.#
#.###.#####.#.#
#.#.#.......#.#
#.#.#####.###.#
#...........#.#
###.#.#####.#.#
#...#.....#.#.#
#.#.#.###.#.#.#
#.....#...#.#.#
#.###.#.#.#.#.#
#S..#.....#...#
###############"""

    m, start, end, barriers = matrix(s.split("\n"))
    assert len(m) == 15
    assert len(m[0]) == 15
    assert start == (13, 1)
    assert end == (1, 13)
    assert len(barriers) == s.count("#")
    assert m[1][13] == "E"
    assert m[13][1] == "S"

    graph = Graph(len(m), len(m[0]), barriers)
    path, cost = a_star(start, end, graph)
    assert cost == 7036

    s = """#################
#...#...#...#..E#
#.#.#.#.#.#.#.#.#
#.#.#.#...#...#.#
#.#.#.#.###.#.#.#
#...#.#.#.....#.#
#.#.#.#.#.#####.#
#.#...#.#.#.....#
#.#.#####.#.###.#
#.#.#.......#...#
#.#.###.#####.###
#.#.#...#.....#.#
#.#.#.#####.###.#
#.#.#.........#.#
#.#.#.#########.#
#S#.............#
#################"""
    m, start, end, barriers = matrix(s.split("\n"))
    graph = Graph(len(m), len(m[0]), barriers)
    path, cost = a_star(start, end, graph)
    assert cost == 11048


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvvs", __file__])
    else:
        main()
