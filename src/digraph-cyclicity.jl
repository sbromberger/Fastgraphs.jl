abstract type Visitor end

"""
```ncycles_n_i(n::Integer, i::Integer)```

Compute the theoretical maximum number of cycles of size `i` in a directed graph of `n`
 vertices.
"""
function ncycles_n_i(n::Integer, i::Integer)
    return binomial(big(n), big(n-i+1)) * factorial(big(n-i))
end

"""
```maxsimplecycles(n::Integer)```

Compute the theoretical maximum number of cycles in a directed graph of `n` vertices,
assuming there are no self-loops.
The formula is coming from [Johnson's paper](http://epubs.siam.org/doi/abs/10.1137/0204007).

# Arguments
* `n`: the number of vertices.
"""

function maxsimplecycles(n::Integer)
    return sum(x -> ncycles_n_i(n, x), 1:(n-1))
end

"""
``` maxsimplecycles(dg::DiGraph, byscc::Bool = true)```

Compute the theoretical maximum number of cycles in the directed graph `dg`.

The computation can be performed assuming the graph is complete or taking into account the
decomposition in strongly connected components. The formula is coming from
[Johnson's paper](http://epubs.siam.org/doi/abs/10.1137/0204007).

# Arguments:
* `dg`: The directed graph to be considered.
* `byscc`: whether it should be computed knowing the strongly connected components of the
 directed or not (default:true)

# Return
* `c`: the theoretical maximum number of cycles.

Note: A more efficient version is possible.
"""
function maxsimplecycles(dg::DiGraph, byscc::Bool = true)
    c = 0
    n = nv(dg)
    if !byscc
        c = maxsimplecycles(n)
    else
        for scc in strongly_connected_components(dg)
            if length(scc) > 1
                c += maxsimplecycles(length(scc))
            end
        end
    end
    return c
end

"""
```
type JohnsonVisitor <: Visitor
stack::Vector{Int}
blocked::Vector{Bool}
blockedmap::Vector{Set{Int}}
end
```

Composite type that regroups the information needed for Johnson's algorithm.

# Arguments
* `stack`: the stack of visited vertices
* `blocked`: boolean for each vertex, tell whether it is blocked or not
* `blockedmap`: tell which vertices to unblock if the key vertex is unblocked
"""
type JohnsonVisitor <: Visitor
    stack::Vector{Int}
    blocked::Vector{Bool}
    blockedmap::Vector{Set{Int}}
end

"""
```JohnsonVisitor(dg::DiGraph)```

Constructor of the visitor, using the directed graph information.
"""
JohnsonVisitor(dg::DiGraph) = JohnsonVisitor(Vector{Int}(),
                                             falses(vertices(dg)),
                                             [Set{Int}() for i in vertices(dg)])

"""
```unblock!(v::T, blocked::Vector{Bool}, B::Vector{Set{Int}})```

Unblock the vertices recursively.

# Arguments
* `v`: the vertex to unblock
* `blocked`: tell whether a vertex is blocked or not
* `B`: the map that tells if the unblocking of one vertex should unblock other vertices
"""
function unblock!(v::Int, blocked::Vector{Bool}, B::Vector{Set{Int}})
    blocked[v] = false
    for w in B[v]
        delete!(B[v], w)
        if blocked[w]
            unblock!(w, blocked, B)
        end
    end
end

"""
```circuit(v::Int, dg::DiGraph, vis::JohnsonVisitor,
allcycles::Vector{Vector{Int}}, vmap:: Vector{Int}, startnode = v)```

One step of the recursive version of simple cycle detection, using a DFS algorithm.

The CIRCUIT function from [Johnson's algorithm](http://epubs.siam.org/doi/abs/10.1137/0204007),
recursive version. Modify the vector of cycles, when needed.

# Arguments
* `v`: the vertex considered in this iteration of the DFS
* `dg`: the digraph from which cycles are computed
* `visitor`: Informations needed for the cycle computation, contains:
    * `stack`: the stack of parent vertices
    * `blocked`: tells whether a vertex has already been explored or not
    * `blockedmap`: mapping of the blocking / unblocking consequences
* `allcycles`: output containing the cycles already detected
* `vmap`: vector map containing the link from the old to the new nodes of the directed graph
* `startnode = v`: optional argument giving the starting node. In the first iteration,
 the same as v, otherwise it should be passed.

# Returns
* `done`: tells whether a circuit has been found in the current exploration.
"""
function circuit(v::Int, dg::DiGraph, vis::JohnsonVisitor, allcycles::Vector{Vector{Int}}, vmap::Vector{Int}, startnode = v)
    done = false
    push!(vis.stack, v)
    vis.blocked[v] = true
    for w in out_neighbors(dg,v)
        if w == startnode
            push!(allcycles, vmap[vis.stack])
            done = true
        elseif !vis.blocked[w]
            circuit(w, dg, vis, allcycles, vmap, startnode) && (done = true)
        end
    end
    if done
        unblock!(v, vis.blocked, vis.blockedmap)
    else
        for w in out_neighbors(dg, v)
            if !in(vis.blockedmap[w], v)
                push!(vis.blockedmap[w], v)
            end
        end
    end
    pop!(vis.stack)
    return done
end


"""
```simplecycles(dg::DiGraph)```

Compute all cycles of the given directed graph, using
[Johnson's algorithm](http://epubs.siam.org/doi/abs/10.1137/0204007).

/!\ The number of cycles grow more than exponentially with the number of vertices,
you might want to use the algorithm with a ceiling -- `getcycles` -- on large directed graphs
(slightly slower). If you want to have an idea of the possible number of cycles,
look at function ```maxsimplecycles(dg::DiGraph, byscc::Bool = true)```.

# Arguments
* `dg`: the directed graph

# Returns
* `cycles`: all the cycles of the directed graph
"""
function simplecycles(dg::DiGraph)
    sccs = strongly_connected_components(dg)
    cycles = Vector{Vector{Int}}()
    for scc in sccs
        for i in 1:(length(scc)-1)
            wdg, vmap = induced_subgraph(dg, scc[i:end])
            #startnode = 1
            #shift!(scc)
            visitor = JohnsonVisitor(wdg)
            circuit(1, wdg, visitor, cycles, vmap)
        end
    end
    return cycles
end


##########################################################
#### Iterative version, using Tasks, of the previous algorithms.
"""
```circuit(v::Int, dg::DiGraph, vis::JohnsonVisitor, vmap::Vector{Int}, cycle::Channel, startnode::Int = v)```

One step of the recursive version of simple cycle detection, using a DFS algorithm.

The CIRCUIT function from [Johnson's algorithm](http://epubs.siam.org/doi/abs/10.1137/0204007),
 recursive and iterative version. Produce a cycle when needed, can be used only inside a
 Task.

# Arguments
* v: the vertex considered in this iteration of the DFS
* dg: the digraph from which cycles are computed
* visitor: Informations needed for the cycle computation, contains:
    * stack: the stack of parent vertices
    * blocked: tells whether a vertex has already been explored or not
    * blockedmap: mapping of the blocking / unblocking consequences
* `vmap`: vector map containing the link from the old to the new nodes of the directed graph
* `cycle`: storage of the channel
* startnode = v: optional argument giving the starting node. In the first iteration,
the same as v, otherwise it should be passed.

# Returns
* done: tells whether a circuit has been found in the current exploration.
"""
function circuit(v::Int, dg::DiGraph, vis::JohnsonVisitor, vmap::Vector{Int}, cycle::Channel, startnode::Int = v)
    done = false
    push!(vis.stack, v)
    vis.blocked[v] = true
    for w in out_neighbors(dg, v)
        if w == startnode
            put!(cycle, vmap[vis.stack])
            done = true
        elseif !vis.blocked[w]
            circuit(w, dg, vis, vmap, cycle, startnode) && (done = true)
        end
    end
    if done
        unblock!(v, vis.blocked, vis.blockedmap)
    else
        for w in out_neighbors(dg, v)
            if !in(vis.blockedmap[w], v)
                push!(vis.blockedmap[w], v)
            end
        end
    end
    pop!(vis.stack)
    return done
end


"""
```itercycles(dg::DiGraph, cycle::Channel)```

Compute all cycles of the given directed graph, using
[Johnson's algorithm](http://epubs.siam.org/doi/abs/10.1137/0204007).

Iterative version of the algorithm, using Tasks to stop the exploration
after a given number of cycles.

# Arguments:
* `dg`: the directed graph we want to explore
* `cycle`: the channel that will be loaded/unloaded
"""
function itercycles(dg::DiGraph, cycle::Channel)
    sccs = strongly_connected_components(dg)
    for scc in sccs
        while length(scc) > 1
            wdg, vmap = induced_subgraph(dg, scc)
            #startnode = 1
            shift!(scc)
            visitor = JohnsonVisitor(wdg)
            circuit(1, wdg, visitor, vmap, cycle)
        end
    end
end

"""
```simplecyclescount(dg::DiGraph, ceiling = 10^6)```

Count the number of cycles in a directed graph, using
[Johnson's algorithm](http://epubs.siam.org/doi/abs/10.1137/0204007).

The ceiling is here to avoir memory overload if there are a lot of cycles in the graph.
Default value is 10^6, but it can be higher or lower. You can use the function
```maxsimplecycles(dg::DiGraph, byscc::Bool = true)``` to get an idea of the
theoretical maximum number or cycles.

# Arguments
* `dg`: the directed graph we are interested in
* `ceiling = 10^6`: the number of cycles after which the search stops

# Returns
* `len`: the number of cycles if below the ceiling, the ceiling otherwise
"""
function simplecyclescount(dg::DiGraph, ceiling = 10^6)
    #t = Task(() -> itercycles(dg))
    len = 0
    for cycle in Iterators.take(Channel(c->itercycles(dg,c)), ceiling)
        len += 1
    end
    return len
end

"""
```simplecycles_iter(dg::DiGraph, ceiling = 10^6)```

Search all cycles of the given directed graph, using
[Johnson's algorithm](http://epubs.siam.org/doi/abs/10.1137/0204007),
up to the ceiling (avoid memory overload).

If the graph is small, the ceiling will not bite and
``simplecycles(dg::DiGraph)`` is more efficient. it avoids the overhead of the
counting and testing if the ceiling is reached.

To get an idea of the possible number of cycles, using function
```maxsimplecycles(dg::DiGraph, byscc::Bool = true)``` on the directed graph.

# Arguments:
* `dg`: the directed graph to explore
* `ceiling = 10^6`: the number of cycles after which the search stops

# Returns:
* all the cycles of the directed graph.
"""
function simplecycles_iter(dg::DiGraph, ceiling = 10^6)
    #t = Task(() -> itercycles(dg))
    return collect(Iterators.take(Channel(c->itercycles(dg,c)), ceiling))
end

"""
```simplecycleslength(dg::DiGraph, ceiling = 10^6)```

Search all cycles of the given directed graph, using
[Johnson's algorithm](http://epubs.siam.org/doi/abs/10.1137/0204007),
and return their length.

To get an idea of the possible number of cycles, using function
```maxsimplecycles(dg::DiGraph, byscc::Bool = true)``` on the directed graph.

# Arguments:
* `dg`: the directed graph to explore

# Returns:
* `cyclelengths`: the lengths of all cycles, the index in the array is the length
* `ncycles`: the number of cycles in the directed graph, up to the ceiling
"""
function simplecycleslength(dg::DiGraph, ceiling = 10^6)
    #t = Task(() -> itercycles(dg))
    ncycles = 0
    cyclelength = zeros(Int, nv(dg))
    for cycle in Iterators.take(Channel(c->itercycles(dg,c)), ceiling)
          cyclelength[length(cycle)] +=1
          ncycles += 1
    end
    return cyclelength, ncycles
end
