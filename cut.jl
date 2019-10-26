struct CutDelta
    cut_edges_before::BitSet
    cut_edges_after::BitSet
    neighbors::BitSet
    Δ::Int64
end

function CutDelta(flip::Flip{Int64}, plan::Plan{Int64}, graph::GraphIndex{Int64})::CutDelta
    cut_edges_before = BitSet(Int64[])
    cut_edges_after = BitSet(Int64[])
    neighbors = BitSet(Int64[])
    @inbounds for index in 1:graph.neighbors_per_node[flip.node]
        neighbor = graph.node_neighbors[index, flip.node]
        if plan.assignment[neighbor] != flip.old_assignment
            edge_index = graph.src_dst_to_edge[flip.node, neighbor]
            push!(cut_edges_before, edge_index)
        end
        if plan.assignment[neighbor] != flip.new_assignment
            edge_index = graph.src_dst_to_edge[flip.node, neighbor]
            push!(cut_edges_after, edge_index)
        end
        if plan.assignment[neighbor] == flip.old_assignment
            push!(neighbors, neighbor)
        end
    end
    Δ = length(cut_edges_after) - length(cut_edges_before)
    return CutDelta(cut_edges_before, cut_edges_after, neighbors, Δ)
end

