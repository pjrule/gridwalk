"""Generates the 10x10 grids in the ReCom paper (in NetworkX format)."""
import json
import click
import networkx as nx
from networkx.readwrite import json_graph

N = 10
SPLIT = 4

@click.command()
@click.option('--horizontal_file', required=True, default='horizontal.json')
@click.option('--vertical_file', required=True, default='vertical.json')
def grids(horizontal_file, vertical_file):
    """Generates two 10x10 grids with vertically striped districts.

    One grid (the A/B grid) has a 40%/60% binary partisan split along
    a horizontal line, perpendicular to the districts. Another grid
    (the A'/B' grid) has a 40%/60% binary partisan split along a vertical
    line, parallel to the districts.

    :param horizontal_file: The JSON file to dump the grid with horizontal
    partisan split to.
    :param vertical_file: The JSON file to dump the grid with horizontal
    partisan split to.
    """
    graph = nx.grid_graph(dim=[N, N])
    for node in graph.nodes:
        graph.nodes[node]['population'] = 1
        graph.nodes[node]['district'] = node[0] + 1

    horizontal_graph = graph.copy()
    vertical_graph = graph.copy()
    for node in graph.nodes:
        a_share = int(node[1] < SPLIT)
        horizontal_graph.nodes[node]['a_share'] = a_share
        horizontal_graph.nodes[node]['b_share'] = 1 - a_share
    for node in vertical_graph.nodes:
        a_share = int(node[0] < SPLIT)
        vertical_graph.nodes[node]['a_share'] = a_share
        vertical_graph.nodes[node]['b_share'] = 1 - a_share

    mapping = {(x, y): (x * N) + y for x, y in horizontal_graph.nodes}
    horizontal_graph = nx.relabel_nodes(horizontal_graph, mapping)
    vertical_graph = nx.relabel_nodes(vertical_graph, mapping)
    with open(horizontal_file, 'w') as adj_file:
        json.dump(json_graph.adjacency_data(horizontal_graph), adj_file)
    with open(vertical_file, 'w') as adj_file:
        json.dump(json_graph.adjacency_data(vertical_graph), adj_file)

if __name__ == '__main__':
    grids()
