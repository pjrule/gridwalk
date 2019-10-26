mutable struct Plan{T}
    n_districts::T
    assignment::Array{T}
    district_populations::Array{T}
    cut_edges::BitSet
    n_cut_edges::T
end

function Plan(graph::GraphIndex, assignment::Array{Int64})::Plan{Int64}
    n_districts = maximum(assignment)
    district_populations = zeros(Int64, n_districts)
    for (index, node_pop) in enumerate(graph.population)
        district_populations[assignment[index]] += node_pop
    end
    cut_edges = BitSet(Int64[])
    for index in 1:graph.n_edges
        left_assignment = assignment[graph.edges[1, index]]
        right_assignment = assignment[graph.edges[2, index]]
        if left_assignment != right_assignment
            push!(cut_edges, index)
        end
    end
    return Plan{Int64}(n_districts, assignment, district_populations,
                       cut_edges, length(cut_edges))
end


