import sys
import pytest


def get_matrix_and_trailheads(lines):
    trailheads = []
    matrix = []
    rows = len(lines)
    cols = len(lines[0])
    [matrix.append([0] * cols) for _ in range(rows)]

    for i, row in enumerate(lines):
        for j, col in enumerate(row.strip()):
            if col == "0":
                trailheads.append((i, j))
            matrix[i][j] = int(col)
    return matrix, trailheads


def neighbors(matrix, r, c):
    return [
        (r + dy, c + dx)
        for dy, dx in [(-1, 0), (1, 0), (0, 1), (0, -1)]
        if r + dy >= 0
        and r + dy < len(matrix)
        and c + dx >= 0
        and c + dx < len(matrix[0])
    ]


def bfs_both(matrix, start, part_two=False):
    def recurse(matrix, queue, visited, path):
        if not queue:
            return 0

        node = queue.pop(0)
        path.append(node)
        if not part_two and node in visited or part_two and tuple(path) in visited:
            return 0

        r, c = node
        val = matrix[r][c]
        visited.add(tuple(path) if part_two else node)

        if val == 9:
            return 1

        return sum(
            recurse(matrix, queue + [(nr, nc)], visited, path)
            for nr, nc in neighbors(matrix, r, c)
            if matrix[nr][nc] == val + 1
        )

    return recurse(matrix, [start], set(), [])


def count_trailheads(matrix, trailheads, part_two=False):
    if part_two:
        return sum(bfs_both(matrix, t, True) for t in trailheads)
    return sum(bfs_both(matrix, t) for t in trailheads)


def main():
    with open("data/input10.txt") as f:
        lines = f.readlines()

    m, ths = get_matrix_and_trailheads(lines)
    print(f"part 1: {count_trailheads(m, ths)}")
    print(f"part 2: {count_trailheads(m, ths, part_two=True)}")


def test_advent_example_part_one():
    s = """89010123
78121874
87430965
96549874
45678903
32019012
01329801
10456732"""
    m, ths = get_matrix_and_trailheads(s.split("\n"))
    assert len(m) == 8
    assert len(ths) == 9
    assert count_trailheads(m, ths) == 36


def test_advent_example_part_two():
    s = """89010123
78121874
87430965
96549874
45678903
32019012
01329801
10456732"""
    m, ths = get_matrix_and_trailheads(s.split("\n"))
    assert len(m) == 8
    assert len(ths) == 9
    assert count_trailheads(m, ths, part_two=True) == 81


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvvs", __file__])
    else:
        main()
