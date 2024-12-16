import sys
import pytest
from enum import StrEnum


BOX = "O"
ROBOT = "@"
EMPTY = "."
WALL = "#"


def num_rows(grid):
    return len(grid)


def num_cols(grid):
    return len(grid[0])


class Direction(StrEnum):
    LEFT = "<"
    RIGHT = ">"
    UP = "^"
    DOWN = "v"


def parse_moves(s: str) -> list[Direction]:
    return [Direction(ch) for ch in s]


def parse_grid(lines):
    robot = None
    matrix = []
    for row, ln in enumerate(lines):
        if "@" in ln:
            robot = (row, ln.index("@"))
        matrix.append([ch for ch in ln])
    return matrix, robot


def move_up(grid, robot):
    y, x = robot
    new_y = y - 1
    ch = grid[new_y][x]
    if ch == "#":
        return grid, robot
    if ch == ".":
        grid[new_y][x], grid[y][x] = grid[y][x], grid[new_y][x]
        return grid, (new_y, x)
    if ch == "O":
        # find the end of the string of boxes
        end = new_y - 1
        while grid[end][x] == "O":
            end -= 1
        if grid[end][x] == ".":
            # move all the boxes
            while end < y:
                grid[end][x], grid[end + 1][x] = grid[end + 1][x], grid[end][x]
                end += 1

            # move the robot
            grid[y][x] = "."
            grid[y - 1][x] = "@"
            return grid, (y - 1, x)
        if grid[end][x] == "#":
            return grid, robot


def move_down(grid, robot):
    y, x = robot
    new_y = y + 1
    ch = grid[new_y][x]
    if ch == "#":
        return grid, robot
    if ch == ".":
        grid[new_y][x], grid[y][x] = grid[y][x], grid[new_y][x]
        return grid, (new_y, x)
    if ch == "O":
        # find the end of the string of boxes
        end = new_y + 1
        while grid[end][x] == "O":
            end += 1
        if grid[end][x] == ".":
            # move all the boxes
            while end > y:
                grid[end][x], grid[end - 1][x] = grid[end - 1][x], grid[end][x]
                end -= 1

            # move the robot
            grid[y][x] = "."
            grid[y + 1][x] = "@"
            return grid, (y + 1, x)
        if grid[end][x] == "#":
            return grid, robot


def move_left(grid, robot):
    y, x = robot
    new_x = x - 1
    ch = grid[y][new_x]
    if ch == "#":
        return grid, robot
    if ch == ".":
        grid[y][new_x], grid[y][x] = grid[y][x], grid[y][new_x]
        return grid, (y, new_x)
    if ch == "O":
        # find the end of the string of boxes
        end = new_x - 1
        while grid[y][end] == "O":
            end -= 1
        if grid[y][end] == ".":
            # move all the boxes
            while end < x:
                grid[y][end], grid[y][end + 1] = grid[y][end + 1], grid[y][end]
                end += 1

            # move the robot
            grid[y][x] = "."
            grid[y][x - 1] = "@"
            return grid, (y, x - 1)
        if grid[y][end] == "#":
            return grid, robot


def move_right(grid, robot):
    y, x = robot
    new_x = x + 1
    ch = grid[y][new_x]
    if ch == "#":
        return grid, robot
    if ch == ".":
        grid[y][new_x], grid[y][x] = grid[y][x], grid[y][new_x]
        return grid, (y, new_x)
    if ch == "O":
        # find the end of the string of boxes
        end = new_x + 1
        while grid[y][end] == "O":
            end += 1
        if grid[y][end] == ".":
            # move all the boxes
            while end > x:
                grid[y][end], grid[y][end - 1] = grid[y][end - 1], grid[y][end]
                end -= 1

            # move the robot
            grid[y][x] = "."
            grid[y][x + 1] = "@"
            return grid, (y, x + 1)
        if grid[y][end] == "#":
            return grid, robot


def tick(grid, robot, move):
    funcs = {
        Direction.LEFT: move_left,
        Direction.UP: move_up,
        Direction.DOWN: move_down,
        Direction.RIGHT: move_right,
    }
    return funcs[move](grid, robot)


def simulate(grid, robot, moves):
    for mv in moves:
        grid, robot = tick(grid, robot, mv)
    return grid


def calculate_gps_sum(grid):
    total = 0
    for i, row in enumerate(grid):
        for j, ch in enumerate(row):
            if ch == "O":
                total += 100 * i + j
    return total


def part_two(data):
    warehouse, moves = data.split("\n\n")
    warehouse, robot = (
        [
            [
                ("[" if i % 2 == 0 else "]") if line[i // 2] == "O" else line[i // 2]
                for i in range(len(line) * 2)
            ]
            for line in data
        ],
        data.index("@"),
    )
    x, y, directions = (
        robot % (len(warehouse[0]) // 2),
        robot // (len(warehouse[0]) // 2),
        {">": 1, "<": -1, "^": -1, "v": 1},
    )
    warehouse[y][x], warehouse[y][x + 1] = ".", "."
    for move in "".join(moves.split()):
        if move in [">", "<"]:
            x1 = x + (directions[move])
            while warehouse[y][x1] in ["[", "]"]:
                x1 += directions[move]
            if warehouse[y][x1] == ".":
                for x2 in range(x1, x, -directions[move]):
                    warehouse[y][x2] = warehouse[y][x2 - directions[move]]
                x += directions[move]
        else:
            boxes = [{(x, y)}]
            while boxes[-1]:
                boxes.append(set())
                for box in boxes[-2]:
                    if warehouse[box[1] + directions[move]][box[0]] == "#":
                        break
                    if warehouse[box[1] + directions[move]][box[0]] == "[":
                        boxes[-1] |= {
                            (box[0], box[1] + directions[move]),
                            (box[0] + 1, box[1] + directions[move]),
                        }
                    elif warehouse[box[1] + directions[move]][box[0]] == "]":
                        boxes[-1] |= {
                            (box[0], box[1] + directions[move]),
                            (box[0] - 1, box[1] + directions[move]),
                        }
                else:
                    continue
                break
            else:
                for row in list(reversed(boxes)):
                    for box in row:
                        (
                            warehouse[box[1] + directions[move]][box[0]],
                            warehouse[box[1]][box[0]],
                        ) = warehouse[box[1]][box[0]], "."
                y += directions[move]
    return sum(
        [
            100 * i + j
            for i, line in enumerate(grid_lines)
            for j, c in enumerate(line)
            if c == "["
        ]
    )


def main():
    grid_lines = []
    move_lines = []
    with open("data/input15.txt") as f:
        for line in f:
            if "#" in line:
                grid_lines.append(line.strip())
            elif line[0] in Direction:
                move_lines.append(line.strip())

    moves = parse_moves("".join(move_lines))
    mat, robot = parse_grid(grid_lines)

    grid = simulate(mat, robot, moves)
    print(f"part 1: {calculate_gps_sum(grid)}")

    with open("data/input15.txt") as f:
        print(f"part 2: {part_two(f.read())}")


def test_move_left():
    # with box blocking
    grid = [[ch for ch in "#..O@..O.#"]]
    grid, robot = move_left(grid, (0, 4))
    assert grid[0] == [ch for ch in "#.O@...O.#"]
    assert robot == (0, 3)

    # with wall blocking
    grid = [[ch for ch in "#.#O@..O.#"]]
    grid, robot = move_left(grid, (0, 4))
    assert grid[0] == [ch for ch in "#.#O@..O.#"]
    assert robot == (0, 4)

    # with two boxes blocking
    grid = [[ch for ch in "#.OO@..O.#"]]
    grid, robot = move_left(grid, (0, 4))
    assert grid[0] == [ch for ch in "#OO@...O.#"]
    assert robot == (0, 3)

    # no blockage
    grid = [[ch for ch in "#...@..O.#"]]
    grid, robot = move_left(grid, (0, 4))
    assert grid[0] == [ch for ch in "#..@...O.#"]
    assert robot == (0, 3)


def test_move_right():
    # with box blocking
    grid = [[ch for ch in "#..@O.O.#"]]
    grid, robot = move_right(grid, (0, 3))
    expected = [ch for ch in "#...@OO.#"]
    assert grid[0] == expected
    assert robot == (0, 4)

    # with wall blocking
    grid = [[ch for ch in "#.#O@#.O.#"]]
    grid, robot = move_right(grid, (0, 4))
    assert grid[0] == [ch for ch in "#.#O@#.O.#"]
    assert robot == (0, 4)

    # with two boxes blocking
    grid = [[ch for ch in "#...@OO..#"]]
    grid, robot = move_right(grid, (0, 4))
    assert grid[0] == [ch for ch in "#....@OO.#"]
    assert robot == (0, 5)

    # no blockage
    grid = [[ch for ch in "#...@.O..#"]]
    grid, robot = move_right(grid, (0, 4))
    assert grid[0] == [ch for ch in "#....@O..#"]
    assert robot == (0, 5)


def test_move_up():
    # with box blocking
    grid = [[ch] for ch in "#..O@..O.#"]
    grid, robot = move_up(grid, (4, 0))
    assert grid == [[ch] for ch in "#.O@...O.#"]
    assert robot == (3, 0)

    # with wall blocking
    grid = [[ch] for ch in "#.#O@..O.#"]
    grid, robot = move_up(grid, (4, 0))
    assert grid == [[ch] for ch in "#.#O@..O.#"]
    assert robot == (4, 0)

    # with two boxes blocking
    grid = [[ch] for ch in "#.OO@..O.#"]
    grid, robot = move_up(grid, (4, 0))
    assert grid == [[ch] for ch in "#OO@...O.#"]
    assert robot == (3, 0)

    # no blockage
    grid = [[ch] for ch in "#...@..O.#"]
    grid, robot = move_up(grid, (4, 0))
    assert grid == [[ch] for ch in "#..@...O.#"]
    assert robot == (3, 0)


def test_move_down():
    # with box blocking
    grid = [[ch] for ch in "#..@O..O.#"]
    grid, robot = move_down(grid, (3, 0))
    assert grid == [[ch] for ch in "#...@O.O.#"]
    assert robot == (4, 0)

    # with wall blocking
    grid = [[ch] for ch in "#..O@#.O.#"]
    grid, robot = move_down(grid, (4, 0))
    assert grid == [[ch] for ch in "#..O@#.O.#"]
    assert robot == (4, 0)

    # with two boxes blocking
    grid = [[ch] for ch in "#...@OO..#"]
    grid, robot = move_down(grid, (4, 0))
    assert grid == [[ch] for ch in "#....@OO.#"]
    assert robot == (5, 0)

    # no blockage
    grid = [[ch] for ch in "#...@..O.#"]
    grid, robot = move_down(grid, (4, 0))
    assert grid == [[ch] for ch in "#....@.O.#"]
    assert robot == (5, 0)


def test_example_part_one():
    s = """########
#..O.O.#
##@.O..#
#...O..#
#.#.O..#
#...O..#
#......#
########"""
    lines = [ln.strip() for ln in s.split("\n")]
    grid, robot = parse_grid(lines)
    assert len(grid) == 8
    assert len(grid[0]) == 8

    assert robot == (2, 2)

    m = "<^^>>>vv<v>>v<<"
    moves = parse_moves(m)
    assert moves == [ch for ch in m]

    grid = simulate(grid, robot, moves)
    expected = [
        ["#", "#", "#", "#", "#", "#", "#", "#"],
        ["#", ".", ".", ".", ".", "O", "O", "#"],
        ["#", "#", ".", ".", ".", ".", ".", "#"],
        ["#", ".", ".", ".", ".", ".", "O", "#"],
        ["#", ".", "#", "O", "@", ".", ".", "#"],
        ["#", ".", ".", ".", "O", ".", ".", "#"],
        ["#", ".", ".", ".", "O", ".", ".", "#"],
        ["#", "#", "#", "#", "#", "#", "#", "#"],
    ]
    assert grid == expected

    assert calculate_gps_sum(grid) == 2028


if __name__ == "__main__":
    import pytest

    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvv", __file__])
    else:
        main()
