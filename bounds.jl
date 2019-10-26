struct Bounds{T}
    min_val::T
    max_val::T
end

function population_bounds(flip::Flip{Int64}, plan::Plan{Int64}, bounds::Bounds{Int64})::Bool
    @inbounds return (plan.district_populations[flip.old_assignment] - flip.population >= bounds.min_val &&
                      plan.district_populations[flip.new_assignment] + flip.population <= bounds.max_val)
end

function contiguous(flip::Flip{Int64},
                    plan::Plan{Int64},
                    graph::GraphIndex{Int64},
                    neighbors::BitSet)::Bool
    source_node = iterate(neighbors)[1]
    pop!(neighbors, source_node)

    queue = Array{Int64}(undef, graph.n_nodes) 
    @inbounds for target_node in neighbors
        visited = zeros(Bool, graph.n_nodes)
        queue[1] = target_node
        visited[target_node] = true
        queue_pos = 1
        queue_len = 2
        found = false
        while queue_len > queue_pos
            curr_node = queue[queue_pos]
            if curr_node == source_node
                found = true
                break
            end
            queue_pos += 1
            for index in 1:graph.neighbors_per_node[curr_node]
                neighbor = graph.node_neighbors[index, curr_node]
                if (!visited[neighbor] && 
                    plan.assignment[neighbor] == flip.old_assignment &&
                    neighbor != flip.node)
                    visited[neighbor] = true
                    queue[queue_len] = neighbor
                    queue_len += 1
                end
            end
        end
        if (queue_len == queue_pos && !found)
            return false
        end
    end
    return true
end
