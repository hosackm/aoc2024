import pytest
import sys
from collections import defaultdict


def build_graph(connections):
    d = defaultdict(set)
    for s in connections:
        a, b = s.split("-")
        d[a].add(b)
        d[b].add(a)
    return dict(d)


def find_triplets(graph):
    triplets = set()
    for v, e in graph.items():
        if len(e) <= 1:
            continue

        edges = list(e)
        for i in range(len(e)):
            for j in range(1, len(e)):
                a = edges[i]
                b = edges[j]
                if not any(vert.startswith("t") for vert in (v, a, b)):
                    continue
                if b in graph[a]:
                    # ensure they're always in the same order
                    # so they don't get counted twice
                    t = tuple(sorted((v, a, b)))
                    triplets.add(t)

    return list(triplets)


def find_cliques(graph):
    cliques = []
    queue = [(set(graph.keys()), set(), set())]
    while queue:
        shrink, grow, remaining = queue.pop()

        if not shrink and not grow:
            cliques.append(remaining)
            continue

        while shrink:
            node = shrink.pop()
            queue.append((shrink & graph[node], grow & graph[node], remaining | {node}))
            grow.add(node)

    return cliques


def largest_clique(graph):
    cliques = find_cliques(graph)
    lan_party = (None,)
    for c in cliques:
        if len(c) > len(lan_party):
            lan_party = sorted(c)
    return lan_party


def main():
    with open("data/input23.txt") as f:
        lines = [ln.strip() for ln in f if ln.strip()]

    g = build_graph(lines)
    print(f"part 1: {len(find_triplets(g))}")
    print(f"part 2: {",".join(largest_clique(g))}")


def test_find_triplets():
    conns = [
        "kh-tc",
        "qp-kh",
        "de-cg",
        "ka-co",
        "yn-aq",
        "qp-ub",
        "cg-tb",
        "vc-aq",
        "tb-ka",
        "wh-tc",
        "yn-cg",
        "kh-ub",
        "ta-co",
        "de-co",
        "tc-td",
        "tb-wq",
        "wh-td",
        "ta-ka",
        "td-qp",
        "aq-cg",
        "wq-ub",
        "ub-vc",
        "de-ta",
        "wq-aq",
        "wq-vc",
        "wh-yn",
        "ka-de",
        "kh-ta",
        "co-tc",
        "wh-qp",
        "tb-vc",
        "td-yn",
    ]
    expected_filtered = [
        ("co", "de", "ta"),
        ("co", "ka", "ta"),
        ("de", "ka", "ta"),
        ("qp", "td", "wh"),
        ("tb", "vc", "wq"),
        ("tc", "td", "wh"),
        ("td", "wh", "yn"),
    ]
    g = build_graph(conns)
    t = find_triplets(g)
    assert len(t) == len(expected_filtered)
    for triplet in expected_filtered:
        triplet in t

    assert len(find_cliques(g)) == 15


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        pytest.main(["-xvvs", __file__])
    else:
        main()
