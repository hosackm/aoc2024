import math
import re
from collections import Counter
from dataclasses import dataclass


@dataclass
class Robot:
    px: int
    py: int
    vx: int
    vy: int

    def tick(self):
        self.px += self.vx
        self.py += self.vy
        self.px %= WIDTH
        self.py %= HEIGHT


WIDTH = 101
HEIGHT = 103
MID_WIDTH = WIDTH // 2
MID_HEIGHT = HEIGHT // 2


def count_quadrants(counts):
    quads = [0, 0, 0, 0]
    for pt, num in counts.items():
        x, y = pt
        quad = 2 * (y > MID_HEIGHT) + int(x > MID_WIDTH)
        quads[quad] += num
    return quads


def display(counts, f=None):
    for r in range(HEIGHT):
        for c in range(WIDTH):
            if c == MID_WIDTH or r == MID_HEIGHT:
                print(" ", end="", file=f)
                continue
            c = counts[(c, r)]
            print(c if c > 0 else ".", end="", file=f)
        print(file=f)
    print(file=f)


def solve(lines):
    final_positions = []
    for robot in parse_robots(lines):
        fx = (robot.px + 100 * robot.vx) % WIDTH
        fy = (robot.py + 100 * robot.vy) % HEIGHT
        if fx != MID_WIDTH and fy != MID_HEIGHT:
            final_positions.append((fx, fy))

    counts = Counter(final_positions)
    return math.prod(count_quadrants(counts))


def simulate(robots: list[Robot], write_to_file=False):
    easter_egg_frame = 0
    min_safety_factor = 1000000000
    max_frames = 10_000
    max_counts = None
    frame = 1

    while frame < max_frames:
        for robot in robots:
            robot.px += robot.vx
            robot.px %= WIDTH
            robot.py += robot.vy
            robot.py %= HEIGHT
        counts = Counter([(r.px, r.py) for r in robots])

        safety_factor = math.prod(count_quadrants(counts))
        if safety_factor < min_safety_factor:
            easter_egg_frame = frame
            min_safety_factor = safety_factor
            max_counts = counts

        frame += 1

    if write_to_file:
        with open("tree_frame.txt", "w") as f:
            display(max_counts, f)

    return easter_egg_frame


def parse_robots(lines):
    robots = []
    for line in lines:
        nums = [int(n) for n in re.findall(r"(-?\d+)", line)]
        robots.append(Robot(*nums))
    return robots


def main():
    with open("data/input14.txt") as f:
        s = f.read().split("\n")

    print(f"part 1: {solve(s)}")
    print(f"part 2: {simulate(parse_robots(s))}")


if __name__ == "__main__":
    main()
