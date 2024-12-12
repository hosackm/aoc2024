from collections import defaultdict
import sys
import pytest


def get_neighbors(grid, ch, r, c):
    return [
        (new_r, new_c)
        for new_r, new_c in [(r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)]
        if len(grid) > new_r >= 0
        and len(grid[0]) > new_c >= 0
        and grid[new_r][new_c] == ch
    ]


def flip_island(grid, start):
    """
    Find points in grid that match the character at grid[start] and are
    connected either vertically or horizontally. Flip each of these character
    to "-" so that we don't double-process a certain grid point.
    """
    r, c = start
    ch = grid[r][c]

    perimeter = 0
    group = set()
    queue = [start]
    while queue:
        node = queue.pop(0)
        nr, nc = node
        if node in group or grid[nr][nc] != ch:
            continue

        group.add(node)
        neighbors = get_neighbors(grid, ch, nr, nc)
        perimeter += 4 - len(neighbors)
        for n in neighbors:
            queue.append(n)

    # flip them so we don't process them in a future iteration
    for ptr, ptc in group:
        grid[ptr][ptc] = "-"

    return list(group), perimeter


def detect_plots(grid):
    """
    Iterate over each x,y co-ordinate and flood outwards to find all
    neighboring co-ordinates that are connected. Return a list of each
    point in a group and the groups perimeter.
    """
    num_rows = len(grid)
    num_cols = len(grid[0])

    groupings = []
    for r in range(num_rows):
        for c in range(num_cols):
            ch = grid[r][c]
            if ch == "-":
                continue
            groupings.append(flip_island(grid, (r, c)))
    return groupings


def parse_grid(lines):
    matrix = [[0] * len(lines[0]) for _ in range(len(lines))]
    for i, line in enumerate(lines):
        for j, ch in enumerate(line.strip()):
            matrix[i][j] = ch
    return matrix


def count_sides(points):
    """
    Given a group of points, return the number of sides
    on the shape that that groups creates.
    """
    sides = defaultdict(set)
    points = set(points)
    for r, c in points:
        if (r, c - 1) not in points:  # left side
            sides[(None, c)].add((r, c))
        if (r, c + 1) not in points:  # right side
            sides[(None, c + 1)].add((r, c))
        if (r - 1, c) not in points:  # up side
            sides[(r, None)].add((r, c))
        if (r + 1, c) not in points:  # down side
            sides[(r + 1, None)].add((r, c))

    # calculate the one-dimensional distance between two points
    def distance(a, b):
        return abs(b[0] - a[0]) + abs(b[1] - a[1])

    total = 0
    total = len(sides)
    for pts in sides.values():
        pts = sorted(list(pts))
        for i in range(1, len(pts)):
            # if points are connected by a distance of 1 then they
            # are considered the same side. Any more and they're
            # a completely new side.
            if distance(pts[i - 1], pts[i]) > 1:
                total += 1
    return total


def calc_price(grid, part_two=False):
    groupings = detect_plots(grid)
    if part_two:
        return sum(len(grp) * count_sides(grp) for grp, _ in groupings)
    return sum(len(grp) * perim for grp, perim in groupings)


def main():
    with open("data/input12.txt") as f:
        lines = [ln.strip() for ln in f]
        grid = parse_grid(lines)
        print(f"part 1: {calc_price(grid)}")

    with open("data/input12.txt") as f:
        lines = [ln.strip() for ln in f]
        grid = parse_grid(lines)
        print(f"part 2: {calc_price(grid, True)}")


def test_part_one():
    s = """\
RRRRIICCFF
RRRRIICCCF
VVRRRCCFFF
VVRCCCJFFF
VVVVCJJCFE
VVIVCCJJEE
VVIIICJJEE
MIIIIIJJEE
MIIISIJEEE
MMMISSJEEE"""
    grid = parse_grid(s.split("\n"))
    assert calc_price(grid) == 1930

    grid = parse_grid(s.split("\n"))
    assert calc_price(grid, True) == 1206


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvvs", __file__])
    else:
        main()
