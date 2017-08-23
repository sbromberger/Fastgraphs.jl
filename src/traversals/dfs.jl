# Parts of this code were taken / derived from Graphs.jl. See LICENSE for
# licensing details.
# DFS implementation optimized from http://www.cs.nott.ac.uk/~psznza/G5BADS03/graphs2.pdf
# Depth-first visit / traversal

abstract type AbstractGraphVisitor end
abstract type AbstractGraphVisitAlgorithm end

#################################################
#
#  Depth-first visit
#
#################################################
"""
    DepthFirst
## Conventions in Breadth First Search and Depth First Search
### VertexColorMap
- color == 0    => unseen
- color < 0     => examined but not closed
- color > 0     => examined and closed

### EdgeColorMap
- color == 0    => unseen
- color == 1     => examined
"""
mutable struct DepthFirst <: AbstractGraphVisitAlgorithm end

function depth_first_visit_impl!(
    g::AbstractGraph,      # the graph
    stack,                          # an (initialized) stack of vertex
    vertexcolormap::AbstractVertexMap,    # an (initialized) color-map to indicate status of vertices
    edgecolormap::AbstractEdgeMap,      # an (initialized) color-map to indicate status of edges
    visitor::AbstractGraphVisitor)  # the visitor


    while !isempty(stack)
        u, udsts, tstate = pop!(stack)
        found_new_vertex = false

        while !done(udsts, tstate) && !found_new_vertex
            v, tstate = next(udsts, tstate)
            u_color = get(vertexcolormap, u, 0)
            v_color = get(vertexcolormap, v, 0)
            v_edge = Edge(u, v)
            e_color = get(edgecolormap, v_edge, 0)
            examine_neighbor!(visitor, u, v, u_color, v_color, e_color) #no return here

            edgecolormap[v_edge] = 1

            if v_color == 0
                found_new_vertex = true
                vertexcolormap[v] = vertexcolormap[u] - 1 #negative numbers
                discover_vertex!(visitor, v) || return
                push!(stack, (u, udsts, tstate))

                open_vertex!(visitor, v)
                vdsts = out_neighbors(g, v)
                push!(stack, (v, vdsts, start(vdsts)))
            end
        end

        if !found_new_vertex
            close_vertex!(visitor, u)
            vertexcolormap[u] *= -1
        end
    end
end

function traverse_graph!(
    g::AbstractGraph,
    alg::DepthFirst,
    s::Integer,
    visitor::AbstractGraphVisitor;
    vertexcolormap = Dict{eltype(g),Int}(),
    edgecolormap = DummyEdgeMap())

    T = eltype(g)
    vertexcolormap[s] = -1
    discover_vertex!(visitor, s) || return

    sdsts = out_neighbors(g, s)
    sstate = start(sdsts)
    stack = [(T(s), sdsts, sstate)]

    depth_first_visit_impl!(g, stack, vertexcolormap, edgecolormap, visitor)
end



# Depth-first visit / traversal
"""
    is_cyclic(g)

Return `true` if graph `g` contains a cycle.

### Implementation Notes
Uses DFS.
"""
function is_cyclic end
@traitfn function is_cyclic(g::::IsDirected)
    T = eltype(g)
    vcolor = zeros(UInt8, nv(g))
    for v in vertices(g)
        vcolor[v] != 0 && continue
        S = Vector{T}([v])
        vcolor[v] = 1
        while !isempty(S)
            u = S[end]
            w = 0
            for n in out_neighbors(g, u)
                if vcolor[n] == 1
                    return true
                elseif vcolor[n] == 0
                    w = n
                    break
                end
            end
            if w != 0
                vcolor[w] = 1
                push!(S, w)
            else
                vcolor[u] = 2
                pop!(S)
            end
        end
    end
    return false
end

# Topological sort using DFS
"""
    topological_sort_by_dfs(g)

Return a [toplogical sort](https://en.wikipedia.org/wiki/Topological_sorting) of a directed
graph `g` as a vector of vertices in topological order.
"""
function toplogical_sort_by_dfs end
@traitfn function topological_sort_by_dfs(g::::IsDirected)
    T = eltype(g)
    vcolor = zeros(UInt8, nv(g))
    verts = Vector{T}()
    for v in vertices(g)
        vcolor[v] != 0 && continue
        S = Vector{T}([v])
        vcolor[v] = 1
        while !isempty(S)
            u = S[end]
            w = 0
            for n in out_neighbors(g, u)
                if vcolor[n] == 1
                    error("The input graph contains at least one loop.")
                elseif vcolor[n] == 0
                    w = n
                    break
                end
            end
            if w != 0
                vcolor[w] = 1
                push!(S, w)
            else
                vcolor[u] = 2
                push!(verts, u)
                pop!(S)
            end
        end
    end
    return reverse(verts)
end

"""
    dfs_tree(g, s)

Return an ordered vector of vertices representing a directed acylic graph based on
depth-first traversal of the graph `g` starting with source vertex `s`.
"""
dfs_tree(g::AbstractGraph, s::Integer; dir=:out) = tree(dfs_parents(g, s; dir=dir))

"""
dfs_parents(g, s[; dir=:out])

Perform a depth-first search of graph `g` starting from vertex `s`.
Return a vector of parent vertices indexed by vertex. If `dir` is specified,
use the corresponding edge direction (`:in` and `:out` are acceptable values).

### Implementation Notes
This version of DFS is iterative.
"""
dfs_parents(g::AbstractGraph, s::Integer; dir=:out) =
(dir == :out) ? _dfs_parents(g, s, out_neighbors) : _dfs_parents(g, s, in_neighbors)

function _dfs_parents(g::AbstractGraph, s::Integer, neighborfn::Function)
    T = eltype(g)
    parents = zeros(T, nv(g))

    seen = zeros(Bool, nv(g))
    S = Vector{T}([s])
    seen[s] = true
    parents[s] = s
    while !isempty(S)
        v = S[end]
        u = 0
        for n in neighborfn(g, v)
            if !seen[n]
                u = n
                break
            end
        end
        if u == 0
            pop!(S)
        else
            seen[u] = true
            push!(S, u)
            parents[u] = v
        end
    end
    return parents
end
