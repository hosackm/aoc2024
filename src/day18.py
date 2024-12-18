import sys
import pytest
from heapq import heappush, heappop
from math import inf


class ProgramSpace:
    def __init__(self, n, barriers):
        self.dim = n
        self.m = [["." for _ in range(n)] for _ in range(n)]

        # use heap to priorty queue to maintain order?
        self.barriers = dict.fromkeys(barriers)
        self.num_dropped = 0

    def drop(self, n):
        all_barriers = list(self.barriers.keys())
        to_drop = all_barriers[self.num_dropped : self.num_dropped + n]
        self.num_dropped += n
        for x, y in to_drop:
            self.m[y][x] = "#"

    def shortest_path(self):
        """
        Calculate shortest path using Djikstra's and return
        the cost and the path with that cost.
        """
        start = (0, 0)
        end = (self.dim - 1, self.dim - 1)

        # the priorty queue of nodes to explore by minimum cost
        pq = []
        heappush(pq, (0, start, []))

        visited = set()
        costs = {start: 0}

        while pq:
            current_cost, (x, y), pth = heappop(pq)
            if (x, y) == end:
                return current_cost, pth + [(x, y)]
            if (x, y) in visited:
                continue

            visited.add((x, y))
            for dx, dy in [(0, -1), (0, 1), (1, 0), (-1, 0)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < self.dim and 0 <= ny < self.dim and self.m[ny][nx] == ".":
                    new_cost = current_cost + 1
                    if (nx, ny) not in costs or new_cost < costs[(nx, ny)]:
                        costs[(nx, ny)] = new_cost
                        heappush(pq, (new_cost, (nx, ny), pth + [(x, y)]))

        return inf, None

    def display_path(self, path):
        path = set(path)
        for y in range(self.dim):
            for x in range(self.dim):
                ch = "."
                if (x, y) in path:
                    ch = "O"
                else:
                    ch = self.m[y][x]
                print(ch, end="")
            print()


def find_first_blocker(n, skip, falling_bytes):
    """
    Find the first byte that blocks all paths to the exit. Start
    with 1024 as a known amount of bytes with a clear exit. Then
    add a single byte at a time. If the byte was in the previous
    path then it could potentially be a blocker. Recompute the
    path to see if this is the case. If so, return that byte
    """
    ps = ProgramSpace(n, falling_bytes)
    ps.drop(skip)
    num_dropped = skip

    cost, path = ps.shortest_path()
    for b in falling_bytes[num_dropped:]:
        ps.drop(1)
        if b in path:
            cost, path = ps.shortest_path()
            if cost == inf:
                return b

    raise Exception("Blocking byte not found...")


def main():
    with open("data/input18.txt") as f:
        falling_bytes = []
        for ln in f:
            x, y = ln.split(",")
            falling_bytes.append((int(x), int(y)))

    ps = ProgramSpace(71, falling_bytes)
    ps.drop(1024)

    cost, _ = ps.shortest_path()
    print(f"part 1: {cost}")

    b = find_first_blocker(71, 1024, falling_bytes)
    print(f"part 2: {b[0]},{b[1]}")


@pytest.fixture
def barriers():
    return [
        (5, 4), (4, 2), (4, 5), (3, 0), (2, 1), (6, 3), (2, 4), (1, 5),
        (0, 6), (3, 3), (2, 6), (5, 1), (1, 2), (5, 5), (2, 5), (6, 5),
        (1, 4), (0, 4), (6, 4), (1, 1), (6, 1), (1, 0), (0, 5), (1, 6), (2, 0),
    ]  # fmt: skip


def test_advent_example_part_one(barriers):
    ps = ProgramSpace(7, barriers)
    ps.drop(12)
    cost, _ = ps.shortest_path()
    assert cost == 22


def test_drop_bytes_subsequently(barriers):
    ps = ProgramSpace(7, barriers)
    ps.drop(12)
    assert ps.num_dropped == 12
    assert sum(row.count("#") for row in ps.m) == 12

    ps.drop(4)
    assert ps.num_dropped == 16
    assert sum(row.count("#") for row in ps.m) == 16


def test_advent_example_part_two(barriers):
    assert find_first_blocker(7, 12, barriers) == (6, 1)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvvs", __file__])
    else:
        main()
