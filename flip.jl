using Random

struct Flip{T}
    node::T
    population::T
    old_assignment::T
    new_assignment::T
end

function random_flip(graph::GraphIndex{Int64}, plan::Plan{Int64})::Flip{Int64}
    edge_index = rand(plan.cut_edges)
    edge_side = rand(Int64[1, 2])
    @inbounds node = graph.edges[edge_side, edge_index]
    @inbounds node_pop = graph.population[node]
    @inbounds old_assignment = plan.assignment[node]
    @inbounds adj_node = graph.edges[3 - edge_side, edge_index]
    @inbounds new_assignment = plan.assignment[adj_node]
    return Flip{Int64}(node, node_pop, old_assignment, new_assignment)
end
