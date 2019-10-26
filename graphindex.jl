using SparseArrays
using LightGraphs

struct GraphIndex{T}
    n_nodes::T
    n_edges::T
    neighbors_per_node::Array{T}
    node_neighbors::Array{T, 2}
    population::Array{T}
    src_dst_to_edge::SparseMatrixCSC{T, T}
    edges::Array{T, 2}
end


function GraphIndex(graph::SimpleGraph, population::Array{Int64})::GraphIndex{Int64}
    n_nodes = nv(graph)
    n_edges = ne(graph)
    all_edges = zeros(Int64, 2, n_edges)
    cut_edges = BitSet(Int64[])

    src_dst_to_edge = spzeros(Int64, n_nodes, n_nodes)
    for (index, edge) in enumerate(edges(graph))
        all_edges[1, index] = src(edge)
        all_edges[2, index] = dst(edge)
        src_dst_to_edge[src(edge), dst(edge)] = index
        src_dst_to_edge[dst(edge), src(edge)] = index
    end

    node_neighbors = zeros(Int64, 5, n_nodes) # Every node in a planar graph has degree ≦5.
    neighbors_per_node = zeros(Int64, n_nodes)
    for index in 1:n_nodes
        for (neighbor_idx, neighbor) in enumerate(neighbors(graph, index))
            node_neighbors[neighbor_idx, index] = neighbor
            neighbors_per_node[index] += 1
        end
    end

    return GraphIndex{Int64}(n_nodes, n_edges, neighbors_per_node, 
                      node_neighbors, population, src_dst_to_edge,
                      all_edges)
end

