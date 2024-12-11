import sys
import pytest
from collections import Counter


def num_stones_after(stones, round):
    counts = Counter(stones)
    for _ in range(round):
        updated_counts = Counter()
        for st, cnt in counts.items():
            slen = len(str(st))
            if st == 0:
                updates = [1]
            elif slen % 2 == 0:
                updates = [int(str(st)[: slen // 2]), int(str(st)[slen // 2 :])]
            else:
                updates = [st * 2024]

            for update in updates:
                updated_counts[update] += cnt

        counts = updated_counts
    return sum(counts.values())


def main():
    with open("data/input11.txt") as f:
        stones = [int(stone) for stone in f.read().strip().split()]
        print(f"part 1: {num_stones_after(stones, 25)}")
        print(f"part 2: {num_stones_after(stones, 75)}")


def test_blink():
    stones = [125, 17]
    assert num_stones_after(stones, 1) == 3
    assert num_stones_after(stones, 2) == 4
    assert num_stones_after(stones, 3) == 5
    assert num_stones_after(stones, 4) == 9
    assert num_stones_after(stones, 5) == 13
    assert num_stones_after(stones, 6) == 22


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvvs", __file__])
    else:
        main()
