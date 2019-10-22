using JSON
using Profile
using Random
using LightGraphs
using SparseArrays

function main()

# Constants (TODO: config file)
min_pop = 354   # constraint (hardcoded): minimum district population
max_pop = 366  # constraint (hardcoded): maximum district population
grid_max_x = 60
grid_max_y = 60

f = open("tests/fixtures/horizontal.json")
parsed = JSON.parse(f)
n_nodes = length(parsed["nodes"])
assignment = zeros(Int64, n_nodes)
population = zeros(Int64, n_nodes)
node_to_coord = zeros(Int64, 2, n_nodes)
coord_to_node = zeros(Int64, grid_max_x, grid_max_y)
graph = SimpleGraph(n_nodes)
for (index, node) in enumerate(parsed["nodes"])
    population[index] = node["population"]
    assignment[index] = node["district"]
    coord_to_node[node["x"], node["y"]] = index
    node_to_coord[1, index] = node["x"]
    node_to_coord[2, index] = node["y"]
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

n_steps = 100000 #000 * 60 * 8
#swaps = zeros(Int64, 2, n_steps)
@profile @inbounds for step in 1:n_steps
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

    # Grid contiguity check: pinch points separating two blocks
    # (expensive w/ DFS!)
    # Grid-specific optimization. May or may not keep.
    """
    x = node_to_coord[1, node]
    y = node_to_coord[2, node]
    left_same = x > 1 && assignment[coord_to_node[x - 1, y]] == old_assignment
    right_same = x < grid_max_x && assignment[coord_to_node[x + 1, y]] == old_assignment
    below_same = y > 1 && assignment[coord_to_node[x, y - 1]] == old_assignment
    above_same = y < grid_max_y && assignment[coord_to_node[x, y + 1]] == old_assignment

    left_diff = (x > 1 && assignment[coord_to_node[x - 1, y]] != old_assignment &&
                 assignment[coord_to_node[x - 1, y]] != new_assignment)
    right_diff = (x < grid_max_x && assignment[coord_to_node[x + 1, y]] != old_assignment &&
                 assignment[coord_to_node[x + 1, y]] != new_assignment)
    below_diff = (y > 1 && assignment[coord_to_node[x, y - 1]] != old_assignment &&
                 assignment[coord_to_node[x, y - 1]] != new_assignment)
    above_diff = (y < grid_max_y && assignment[coord_to_node[x, y + 1]] != old_assignment &&
                 assignment[coord_to_node[x, y + 1]] != new_assignment)
    pinch = (((left_same && right_same) && (above_diff || below_diff)) ||
             ((above_same && below_same) && (left_diff || right_diff)))
    if pinch
        continue
    end
    """

    # Contiguity check
    # (Algorithm borrowed from single_flip_contiguous() in GerryChain)
    # Pick a node that is
    #   (1) A neighbor of the node to be flipped
    #   (2) In the district the node to be flipped is currently in
    # ...and ensure that it is connected to all other nodes meeting
    # these criteria.
    contiguous = true
    n_neighbors = length(neighbors_before)
    # TODO: in general, the all_visited trick won't give
    # global contiguity, but it will allow us to fold queues
    # together. It should give global contiguity for grids.
    all_visited = zeros(Int64, n_nodes)
    visited = zeros(Bool, n_nodes, n_neighbors)
    queues = zeros(Int64, n_nodes, n_neighbors)
    active = ones(Bool, n_neighbors)
    queue_pos = ones(Int64, n_neighbors)
    queue_len = ones(Int64, n_neighbors)
    iters_per_neighbor = 8  # TODO: dynamic
    for (index, target_node) in enumerate(neighbors_before)
        queues[1, index] = target_node
        all_visited[target_node] = index
    end
    iter = 1
    curr_queue = 1
    while active[curr_queue]
        # Visit the current queue and try to keep exploring the subgraph.
        # If we hit a node that's been visited by another queue but not
        # this queue, we have contiguity (TODO: verify; there should only
        # ever be two queues in the case of grids, but not in general...),
        # so we stop exploring. If we get  to the end of the current queue
        # and there's still nodes left on another queue, we stop.
        curr_node = queues[queue_pos[curr_queue], curr_queue]
        queue_pos[curr_queue] += 1

        # skip over nodes in the current queue that we don't have
        # to traverse anymore because they've been merged in
        if all_visited[curr_node] == curr_queue || !active[all_visited[curr_node]]
            for index in 1:neighbors_per_node[curr_node]
                neighbor = node_neighbors[index, curr_node]
                if (all_visited[neighbor] != curr_queue && assignment[neighbor] == old_assignment
                    && neighbor != node)
                    if all_visited[neighbor] > 0
                        # We've stumbled upon a path from another queue!
                        # Fold the visited list of the current queue in
                        # with the discovered queue.
                        other = all_visited[neighbor]
                        for i in 1:queue_len[curr_queue]
                            visited_node = queues[i, curr_queue]
                            visited[visited_node, other] = true
                        end
                        left = queue_len[curr_queue] - queue_pos[curr_queue] + 1
                        curr_start = queue_pos[curr_queue] - 1
                        other_start = queue_len[other]
                        for i in 1:left
                            queues[other_start + i, other] = queues[curr_start + i, curr_queue]
                        end
                        queue_len[other] += left
                        active[curr_queue] = false
                        break
                    end
                    all_visited[neighbor] = curr_queue
                    visited[neighbor, curr_queue] = true
                    queue_len[curr_queue] += 1
                    queues[queue_len[curr_queue], curr_queue] = neighbor
                end
            end
        end

        if queue_pos[curr_queue] > queue_len[curr_queue] && active[curr_queue]
            # If the current queue is still active but we've gotten to
            # the end, we better have hit every neighbor node! Otherwise,
            # contiguity fails.
            failed = false
            for target_node in neighbors_before
                if !visited[target_node, curr_queue]
                    failed = true
                end
            end
            if failed
                contiguous = false
                active[curr_queue] = false
                continue
            end
        end

        if iter == iters_per_neighbor || !active[curr_queue]
            # Roll over to the next active queue.
            # We roll over if we're done iterating on a particular
            # queue for now if we've merged the current queue with
            # another.
            iter = 1
            for index in 1:n_neighbors
                curr_queue += 1
                if curr_queue > n_neighbors
                    curr_queue = 1
                end
                if active[curr_queue]
                    break
                end
            end
        else
            iter += 1 
        end
    end

    if !contiguous
        continue
    #elseif pinch
    #    println("contiguous AND pinched (", node_to_coord[1, node], ", ", node_to_coord[2, node], " ", old_assignment, " -> ", new_assignment, ")")
    #    println(assignment)
    end

    assignment[node] = new_assignment
    #swaps[1, step] = node
    #swaps[2, step] = new_assignment
    #println(node, " ", new_assignment)
    #println(assignment)
    setdiff!(cut_edges, cut_edges_before)
    union!(cut_edges, cut_edges_after)
    district_populations[old_assignment] -= node_pop
    district_populations[new_assignment] += node_pop
end
println()
println(cut_edges)
println(assignment)
end

@time main()
