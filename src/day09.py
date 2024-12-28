def get_files(layout):
    files = []
    start = 0
    end = start + 1
    while end < len(layout):
        while end < len(layout) and layout[end] == layout[start]:
            end += 1

        if layout[start] != ".":
            files.append([start, end])
        start = end
        end = start + 1
    return files


def get_spaces(layout):
    spaces = []
    start = layout.index(".")
    end = start + 1
    while end < len(layout):
        while end < len(layout) and layout[end] == layout[start]:
            end += 1

        if layout[start] == ".":
            spaces.append([start, end])
        start = end
        end = start + 1
    return spaces


def compress_part_two(layout):
    reverse_files = get_files(layout)[::-1]
    spaces = get_spaces(layout)

    for file in reverse_files:
        file_start, file_end = file
        file_len = file_end - file_start
        for space in spaces:
            space_start, space_end = space
            space_len = space_end - space_start

            if file_start < space_start:
                break

            if file_len <= space_len:
                for i in range(file_len):
                    layout[space_start + i] = layout[file_start]
                    layout[file_end - i - 1] = "."

                # reassign to space list for next iteration
                space[0] = space_start + file_len
                break

    return layout


def compress(layout, part_two=False):
    if part_two:
        layout = compress_part_two(layout)
    else:
        i = 0
        j = len(layout) - 1
        while i < j:
            if layout[i] == ".":
                layout[i] = layout[j]
                layout[j] = "."
                while layout[j] == ".":
                    j -= 1
            i += 1
    return layout


def get_layout(s):
    layout = []
    for i, ch in enumerate(s):
        if i % 2 == 0:
            layout += [str(i // 2)] * int(ch)
        else:
            layout += ["."] * int(ch)
    return layout


def calc_checksum(compressed):
    return sum(i * int(ch) for i, ch in enumerate(compressed) if ch != ".")


def fragment(s, part_two=False):
    layout = get_layout(s)
    return calc_checksum(compress(layout[:], part_two))


def main():
    with open("data/input9.txt") as f:
        s = f.read()
        print(f"part 1: {fragment(s)}")
        print(f"part 2: {fragment(s, True)}")


def test_advent_examples():
    s = "2333133121414131402"
    assert fragment(s) == 1928
    assert fragment(s, True) == 2858


if __name__ == "__main__":
    import pytest
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvv", __file__])
    else:
        main()
