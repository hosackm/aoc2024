import operator as ops


def parse(lines):
    initial_states = {}
    gates = {}

    states_lines, gates_lines = lines.split("\n\n")
    for ln in states_lines.split("\n"):
        name, state = ln.split(": ")
        initial_states[name] = int(state)

    for ln in gates_lines.split("\n"):
        in1, op, in2, _, out = ln.split(" ")
        in1, in2 = sorted((in1, in2))
        gates[(in1, in2, op)] = out

    return initial_states, gates


def loop(gates, states):
    funcs = {"AND": ops.__and__, "XOR": ops.__xor__, "OR": ops.__or__}
    queue = [(*k, v) for k, v in gates.items()]
    while queue:
        group = queue.pop(0)
        in1, in2, op, out = group
        if in1 not in states or in2 not in states:
            queue.append(group)
            continue
        states[out] = funcs[op](states[in1], states[in2])
    return states


def get_binary(states):
    bits = (f"z{n:02}" for n in range(int(max(states)[1:]), -1, -1))
    return int("".join(str(states[b]) for b in bits), 2)


def find_swapped_pins(gates):
    reverse = {v: k for k, v in gates.items()}

    def swap(a, b):
        r, g = reverse, gates
        r[a], r[b] = r[b], r[a]
        g[reverse[a]], g[reverse[b]] = g[reverse[b]], g[reverse[a]]

    carry = None
    swapped = set()
    for i in range(int(max(reverse)[1:])):
        x = f"x{i:02}"
        y = f"y{i:02}"
        z = f"z{i:02}"
        x_xor_y = gates[x, y, "XOR"]
        x_and_y = gates[x, y, "AND"]

        if carry is None:
            carry = x_and_y
            continue

        a, b = sorted((carry, x_xor_y))
        key = (a, b, "XOR")
        if key not in gates:
            a, b = tuple(set(reverse[z][:2]) ^ set([a, b]))
            swapped.add(a)
            swapped.add(b)
            swap(a, b)
        elif gates[key] != z:
            swapped.add(gates[key])
            swapped.add(z)
            swap(z, gates[key])

        # reset because they could've swapped at this point
        x_xor_y = gates[x, y, "XOR"]
        x_and_y = gates[x, y, "AND"]

        # resolve the carry bit
        carry = gates[*sorted((carry, x_xor_y)), "AND"]
        carry = gates[*sorted((carry, x_and_y)), "OR"]

    return ",".join(sorted(swapped))


def main():
    with open("data/input24.txt") as f:
        states, gates = parse(f.read())

    states = loop(gates, states)
    print(f"part 1: {get_binary(states)}")
    print(f"part 2: {find_swapped_pins(gates)}")


if __name__ == "__main__":
    main()
