import pytest
import sys
from collections import defaultdict


def rollover(num):
    num = (num ^ (num * 64)) % 16777216
    num = (num ^ (num // 32)) % 16777216
    return (num ^ (num * 2048)) % 16777216


def get_prices(num, n=2000):
    prices = []
    prices.append(num % 10)
    for _ in range(n + 1):
        num = rollover(num)
        prices.append(num % 10)
    return prices


def get_diffs(prices):
    return [prices[i] - prices[i - 1] for i in range(1, len(prices))]


def sliding_window(prices, diffs):
    d = {}
    for i in range(4, len(prices)):
        seq = tuple(diffs[i - 4 : i])
        if seq not in d:  # only first instance of sequence can be used
            d[seq] = prices[i]
    return d


def final(num, n=2000):
    for _ in range(n):
        num = rollover(num)
    return num


def make_sequences(num):
    p = get_prices(num)
    d = get_diffs(p)
    return sliding_window(p, d)


def main():
    with open("data/input22.txt") as f:
        nums = [int(ln.strip()) for ln in f if ln.strip()]

    finals = [final(num) for num in nums]
    print(f"part 1: {sum(finals)}")

    prices = [get_prices(start) for start in nums]
    diffs = [get_diffs(price) for price in prices]
    sequence_trackers = [
        sliding_window(price, diff) for price, diff in zip(prices, diffs)
    ]

    profits = defaultdict(int)
    for tracker in sequence_trackers:
        for sequence, profit in tracker.items():
            profits[sequence] += profit

    max_score = max(v for v in profits.values())
    print(f"part 2: {max_score}")


def test_example_part_one_mini():
    num = 123
    expected = [
        15887950,
        16495136,
        527345,
        704524,
        1553684,
        12683156,
        11100544,
        12249484,
        7753432,
        5908254,
    ]
    for exp in expected:
        num = rollover(num)
        assert num == exp


def test_example_part_one():
    expected = [
        (1, 8685429),
        (10, 4700978),
        (100, 15273692),
        (2024, 8667524),
    ]
    for num, exp in expected:
        assert final(num) == exp


def test_example_part_two():
    expected = [
        (123, 3),
        (15887950, 0),
        (16495136, 6),
        (527345, 5),
        (704524, 4),
        (1553684, 4),
        (12683156, 6),
        (11100544, 4),
        (12249484, 4),
        (7753432, 2),
    ]
    prices = get_prices(123, n=10)
    for p, (_, exp) in zip(prices, expected):
        assert p == exp

    expected = [-3, 6, -1, -1, 0, 2, -2, 0, -2, 2, -4]
    diffs = get_diffs(prices)
    assert diffs == expected

    buying_points = sliding_window(prices, diffs)
    assert buying_points[(-1, -1, 0, 2)] == 6

    sequence_length = 4
    assert len(buying_points) == len(prices) - sequence_length


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvvs", __file__])
    else:
        main()
