def get_directional_strings(mat: list[str], x: int, y: int) -> list[str]:
    strings = []
    if mat[y][x] != "X" and mat[y][x] != "S":
        return []

    # right
    if x < len(mat[0]) - 3:
        strings.append(mat[y][x : x + 4])
    # left
    if x >= 3:
        strings.append(mat[y][x] + mat[y][x - 1] + mat[y][x - 2] + mat[y][x - 3])
    # up
    if y >= 3:
        strings.append(mat[y][x] + mat[y - 1][x] + mat[y - 2][x] + mat[y - 3][x])
    # down
    if y < len(mat) - 3:
        strings.append(mat[y][x] + mat[y + 1][x] + mat[y + 2][x] + mat[y + 3][x])
    # up-left
    if y >= 3 and x >= 3:
        strings.append(
            mat[y][x] + mat[y - 1][x - 1] + mat[y - 2][x - 2] + mat[y - 3][x - 3]
        )
    # up-right
    if y >= 3 and x < len(mat[0]) - 3:
        strings.append(
            mat[y][x] + mat[y - 1][x + 1] + mat[y - 2][x + 2] + mat[y - 3][x + 3]
        )
    # down-left
    if y < len(mat) - 3 and x >= 3:
        strings.append(
            mat[y][x] + mat[y + 1][x - 1] + mat[y + 2][x - 2] + mat[y + 3][x - 3]
        )
    # down-right
    if y < len(mat) - 3 and x < len(mat[0]) - 3:
        strings.append(
            mat[y][x] + mat[y + 1][x + 1] + mat[y + 2][x + 2] + mat[y + 3][x + 3]
        )

    return strings


def count_crossing_mas(mat) -> int:
    total = 0
    rows = len(mat[0])
    cols = len(mat)
    for j in range(rows):
        for i in range(cols):
            if i == 0 or i == rows - 1 or j == 0 or j == cols - 1:
                continue

            if mat[j][i] != "A":
                continue

            # check_cross
            diag1 = mat[j - 1][i - 1] + mat[j][i] + mat[j + 1][i + 1]
            diag2 = mat[j - 1][i + 1] + mat[j][i] + mat[j + 1][i - 1]
            if (diag1 == "MAS" or diag1 == "SAM") and (
                diag2 == "MAS" or diag2 == "SAM"
            ):
                total += 1
    return total


def count(mat: list[str]) -> int:
    total = 0
    for i in range(len(mat[0])):
        for j in range(len(mat)):
            total += sum(s == "XMAS" for s in get_directional_strings(mat, i, j))
    return total


def load_input(f):
    mat = []
    for ln in f:
        mat.append(ln.strip())
    return mat


def main():
    with open("data/input4.txt") as f:
        mat = load_input(f)
        print(f"part 1: {count(mat)}")
        print(f"part 2: {count_crossing_mas(mat)}")


def test_advent_example():
    from io import StringIO

    test_input = StringIO("""MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX""")
    mat = load_input(test_input)
    assert len(mat) == 10
    assert len(mat[0]) == 10
    assert count(mat) == 18

    test_input = StringIO(""".M.S......
..A..MSMS.
.M.S.MAA..
..A.ASMSM.
.M.S.M....
..........
S.S.S.S.S.
.A.A.A.A..
M.M.M.M.M.
..........""")
    mat = load_input(test_input)
    assert count_crossing_mas(mat) == 9


if __name__ == "__main__":
    main()
