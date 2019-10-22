using JSON


using Profile
using Random
using LightGraphs
using SparseArrays


function main()
# Constants (TODO: config file)
min_pop = 0.99 * 360  # constraint (hardcoded): minimum district population
max_pop = 1.01 * 360  # constraint (hardcoded): maximum district population

f = open("tests/fixtures/horizontal.json")
parsed = JSON.parse(f)
n_nodes = length(parsed["nodes"])
assignment = zeros(Int64, n_nodes)
population = zeros(Int64, n_nodes)
graph = SimpleGraph(n_nodes)
for (index, node) in enumerate(parsed["nodes"])
    population[index] = node["population"]
    assignment[index] = node["district"]
end
for (index, edges) in enumerate(parsed["adjacency"])
    for edge in edges
        if edge["id"] + 1 > index
            # Julia arrays are 1-indexed, but NetworkX (and Python in general)
            # use 0-indexing. We increment each value in the ID field of each
            # edge by 1 to account for this.
            add_edge!(graph, index, edge["id"] + 1)
        end
    end
end

n_edges = ne(graph)
all_edges = zeros(Int64, 2, n_edges)
cut_edges = BitSet(Int64[])
src_dst_to_edge = spzeros(Int64, n_nodes, n_nodes)
for (index, edge) in enumerate(edges(graph))
    all_edges[1, index] = src(edge)
    all_edges[2, index] = dst(edge)
    src_dst_to_edge[src(edge), dst(edge)] = index
    src_dst_to_edge[dst(edge), src(edge)] = index
    if assignment[src(edge)] != assignment[dst(edge)]
        push!(cut_edges, index)
    end
end

node_neighbors = zeros(Int64, 8, n_nodes) # TODO: how many nodes can we have? 
neighbors_per_node = zeros(Int64, n_nodes)
for index in 1:n_nodes
    for (neighbor_idx, neighbor) in enumerate(neighbors(graph, index))
        node_neighbors[neighbor_idx, index] = neighbor
        neighbors_per_node[index] += 1
    end
end

max_cut_edges = 2 * length(cut_edges)  # constraint: max. cut edges
n_districts = maximum(assignment)
district_populations = zeros(Int64, n_districts)
for (index, node_pop) in enumerate(population)
    district_populations[assignment[index]] += node_pop
end
println(cut_edges)
println(assignment)

n_steps = 1000000 #12000000 * 60 * 8
#swaps = zeros(Int64, 2, n_steps)
max_path_length = zeros(Int64, 1)
accepted = 0
@time @inbounds for step in 1:n_steps
    edge_index = rand(cut_edges)
    edge_side = rand(Int64[1, 2])
    node = all_edges[edge_side, edge_index]
    node_pop = population[node]
    old_assignment = assignment[node]
    adj_node = all_edges[3 - edge_side, edge_index]
    new_assignment = assignment[adj_node]
    #println("proposed: ", node, " ", old_assignment, " -> ", new_assignment)

    # Population check
    if district_populations[old_assignment] - node_pop < min_pop
        #println("FAILED: old pop too small (", district_populations[old_assignment] - node_pop, ")") 
        continue
    end
    if district_populations[new_assignment] + node_pop > max_pop
        #println("FAILED: new pop too big (", district_populations[new_assignment] + node_pop, ")") 
        continue
    end

    # Cut edges check
    neighbors_before = BitSet(Int64[])
    cut_edges_before = BitSet(Int64[])
    cut_edges_after = BitSet(Int64[])
    for index in 1:neighbors_per_node[node]
        neighbor = node_neighbors[index, node]
        if assignment[neighbor] != old_assignment
            edge_index = src_dst_to_edge[node, neighbor]
            push!(cut_edges_before, edge_index)
        elseif assignment[neighbor] != new_assignment
            edge_index = src_dst_to_edge[node, neighbor]
            push!(cut_edges_after, edge_index)
        end
        if assignment[neighbor] == old_assignment
            push!(neighbors_before, neighbor)
        end
    end
    Δcut = length(cut_edges_after) - length(cut_edges_before)
    if length(cut_edges) + Δcut > max_cut_edges
        #println("FAILED: too many cut edges")
        continue
    end

    # Contiguity check
    # (Algorithm borrowed from single_flip_contiguous() in GerryChain)
    # Pick a node that is
    #   (1) A neighbor of the node to be flipped
    #   (2) In the district the node to be flipped is currently in
    # ...and ensure that it is connected to all other nodes meeting
    # these criteria.
    contiguous = true
    source_node = iterate(neighbors_before)[1]
    all_visited = zeros(Bool, n_nodes)
    all_visited[source_node] = true
    for target_node in neighbors_before
        if all_visited[target_node]
            continue
        end
        queue = zeros(Int64, n_nodes)  # TODO: max number of nodes
        visited = zeros(Bool, n_nodes) 
        queue_pos = 1
        queue_len = 1
        found = false
        # Populate the queue with the target node's immediate neighbors.
        for index in neighbors_per_node[target_node]
            neighbor = node_neighbors[index, target_node]
            if neighbor != node && assignment[neighbor] == old_assignment
                queue[queue_len] = neighbor
                queue_len += 1
            end
        end
        # Run a DFS.
        while queue_len > queue_pos
            curr_node = queue[queue_pos]
            queue_pos += 1
            if curr_node == source_node
                found = true
                break
            end
            for index in 1:neighbors_per_node[curr_node]
                neighbor = node_neighbors[index, curr_node]
                if (!visited[neighbor] && assignment[neighbor] == old_assignment
                    && neighbor != node)
                    visited[neighbor] = true
                    all_visited[neighbor] = true
                    queue[queue_len] = neighbor
                    queue_len += 1
                end
            end
        end
        if !found
            #println("queue_pos: ", queue_pos, " [not contiguous]")
            contiguous = false
            break
        else
            #println("queue_pos: ", queue_pos, " [contiguous]")
            if queue_pos > max_path_length[1]
                max_path_length[1] = queue_pos
            end
        end
    end
    if !contiguous
        #println("FAILED: not contiguous")
        continue
    end

    assignment[node] = new_assignment
    #iswaps[1, step] = node
    #swaps[2, step] = new_assignment
    #println(node, " ", new_assignment)
    setdiff!(cut_edges, cut_edges_before)
    union!(cut_edges, cut_edges_after)
    district_populations[old_assignment] -= node_pop
    district_populations[new_assignment] += node_pop
    accepted += 1
end
println()
println(cut_edges)
println(assignment)
println("max path length: ", max_path_length[1])
println("accepted ", accepted, "/", n_steps)
end

main()
