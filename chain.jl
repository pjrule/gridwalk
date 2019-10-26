using JSON
using Profile
using LightGraphs

include("graphindex.jl")
include("plan.jl")
include("flip.jl")
include("cut.jl")
include("bounds.jl")

function load_graph(path::String)::Dict
    f = open(path)
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
    return Dict("population" => population,
                "assignment" => assignment,
                "graph" => graph)
end

function update!(plan::Plan{Int64}, flip::Flip{Int64}, cut::CutDelta)
    @inbounds plan.assignment[flip.node] = flip.new_assignment
    setdiff!(plan.cut_edges, cut.cut_edges_before)
    union!(plan.cut_edges, cut.cut_edges_after)
    @inbounds plan.district_populations[flip.old_assignment] -= flip.population
    @inbounds plan.district_populations[flip.new_assignment] += flip.population
    plan.n_cut_edges += cut.Δ
end

function next!(plan::Plan{Int64}, graph::GraphIndex{Int64},
               pop_bounds::Bounds{Int64}, cut_edges_bound::Int64)::Bool
        flip = random_flip(graph, plan)
        if !population_bounds(flip, plan, pop_bounds)
            return false
        end
        cut = CutDelta(flip, plan, graph)
        if plan.n_cut_edges + cut.Δ  > cut_edges_bound
            return false
        end
        if !contiguous(flip, plan, graph, copy(cut.neighbors))
            return false
        end
        update!(plan, flip, cut)
        return true
end

function main(graph_path)
    # Constants (TODO: config file)
    n_steps = 10000000 #12000000 * 60 * 8
    window_size = 1000000
    min_pop = Int64(0.99 * 1000)  # constraint (hardcoded): minimum district population
    max_pop = Int64(1.01 * 1000)  # constraint (hardcoded): maximum district population
    pop_bounds = Bounds{Int64}(min_pop, max_pop)

    graph_data = load_graph(graph_path)
    graph = GraphIndex(graph_data["graph"], graph_data["population"])
    plan = Plan(graph, graph_data["assignment"])

    max_cut_edges = 2 * plan.n_cut_edges  # constraint: max. cut edges
    accepted_in_window = 0
    accepted = 0
    for step in 1:n_steps
        if step % window_size == 0
            println("window: ", accepted_in_window, "/", window_size)
            accepted_in_window = 0
        end
        if next!(plan, graph, pop_bounds, max_cut_edges)
            accepted += 1
            accepted_in_window += 1
        end
    end
    println()
    println(plan.assignment)
    println("accepted ", accepted, "/", n_steps)
end

@time main("tests/fixtures/horizontal.json")
