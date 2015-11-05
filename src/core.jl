abstract AbstractPathState


"""A type representing a single edge between two vertices of a graph."""
typealias Edge Pair{Int,Int}

"""Return source of an edge."""
src(e::Edge) = e.first
"""Return destination of an edge."""
dst(e::Edge) = e.second

@deprecate rev(e::Edge) reverse(e)

==(e1::Edge, e2::Edge) = (e1.first == e2.first && e1.second == e2.second)

function show(io::IO, e::Edge)
    print(io, "edge $(e.first) - $(e.second)")
end

"""A type representing an undirected graph."""
type Graph
    vertices::UnitRange{Int}
    edges::Set{Edge}
    fadjlist::Vector{Vector{Int}} # [src]: (dst, dst, dst)
end

"""A type representing a directed graph."""
type DiGraph
    vertices::UnitRange{Int}
    edges::Set{Edge}
    fadjlist::Vector{Vector{Int}} # [src]: (dst, dst, dst)
    badjlist::Vector{Vector{Int}} # [dst]: (src, src, src)
end

typealias SimpleGraph Union{Graph, DiGraph}


"""Return the vertices of a graph."""
vertices(g::SimpleGraph) = g.vertices

"""Return the edges of a graph.
NOTE: returns a reference, not a copy. Do not modify result."""
edges(g::SimpleGraph) = g.edges

"""Returns the forward adjacency list of a graph.

The Array, where each vertex the Array of destinations for each of the edges eminating from that vertex.
This is equivalent to:

    fadj = [Vector{Int}() for _ in vertices(g)]
    for e in edges(g)
        push!(fadj[src(e)], dst(e))
    end
    fadj

For most graphs types this is pre-calculated.

The optional second argument take the `v`th vertex adjacency list, that is:

    fadj(g, v::Int) == fadj(g)[v]

NOTE: returns a reference, not a copy. Do not modify result.
"""
fadj(g::SimpleGraph) = g.fadjlist
fadj(g::SimpleGraph, v::Int) = g.fadjlist[v]


"""Returns true if all of the vertices and edges of `g` are contained in `h`."""
function issubset{T<:SimpleGraph}(g::T, h::T)
    (gmin, gmax) = extrema(vertices(g))
    (hmin, hmax) = extrema(vertices(h))
    return (hmin <= gmin <= gmax <= hmax) && issubset(edges(g), edges(h))
end


"""Add `n` new vertices to the graph `g`."""
function add_vertices!(g::SimpleGraph, n::Integer)
    for i = 1:n
        add_vertex!(g)
    end
    return nv(g)
end

"""Return true if the graph `g` has an edge from `src` to `dst`."""
has_edge(g::SimpleGraph, src::Int, dst::Int) = has_edge(g,Edge(src,dst))

"""Return an Array of the edges in `g` that arrive at vertex `v`."""
in_edges(g::SimpleGraph, v::Int) = [Edge(x,v) for x in badj(g,v)]
"""Return an Array of the edges in `g` that emanate from vertex `v`."""
out_edges(g::SimpleGraph, v::Int) = [Edge(v,x) for x in fadj(g,v)]

"""Return true if `v` is a vertex of `g`."""
has_vertex(g::SimpleGraph, v::Int) = v in vertices(g)

"""The number of vertices in `g`."""
nv(g::SimpleGraph) = length(vertices(g))
"""The number of edges in `g`."""
ne(g::SimpleGraph) = length(edges(g))

"""Add a new edge to `g` from `src` to `dst`.

Note: An exception will be raised if the edge is already in the graph
or if the vertex is not contained in the graph.
"""
function add_edge!(g::SimpleGraph, e::Edge)
    has_edge(g,e) && error("Edge $e already in graph")
    (has_vertex(g,src(e)) && has_vertex(g,dst(e))) || throw(BoundsError())
    unsafe_add_edge!(g,e)
end

add_edge!(g::SimpleGraph, src::Int, dst::Int) = add_edge!(g, Edge(src, dst))

"""Remove the edge from `src` to `dst`.

Note: An exception will be raised if the edge is not in the graph.
"""
rem_edge!(g::SimpleGraph, src::Int, dst::Int) = rem_edge!(g, Edge(src,dst))

<<<<<<< HEAD
<<<<<<< HEAD
"""Remove the vertex `v` from graph `g`.
=======
"""Remove the vertex `v` from the graph `g`.
>>>>>>> change rem_edge
=======
"""Remove the vertex `v` from graph `g`.
>>>>>>> finish work on vertex removal
This operation has to be performed carefully if one keeps external data structures indexed by
edges or vertices in the graph, since internally the removal is performed swapping the vertices `v`  and `n=nv(g)`,
and removing the vertex `n` from the graph.
After removal the vertices in the ` g` will be indexed by 1:n-1.
<<<<<<< HEAD
This is an O(k^2) operation, where `k` is the max of the degrees of vertices `v` and `n`.
Note: An exception will be raised if the vertex `v`  is not in the `g`.
"""
function rem_vertex!(g::SimpleGraph, v::Int)
    v in vertices(g) || throw(BoundsError())
    n = nv(g)

    edgs = in_edges(g, v)
    for e in edgs
        unsafe_rem_edge!(g, e)
    end
    neigs = copy(in_neighbors(g, n))
=======
This is an O(k) operation, where `k` is the max of the degree of vertices `v` and `n`.
Note: An exception will be raised if the vertex `v`  is not in the `g`.
"""
function rem_vertex!(g::SimpleGraph, v::Int)
    v in vertices(g) || throw(BoundsError())
    n = nv(g)

    edgs = in_edges(g, v)
    for e in edgs
        unsafe_rem_edge!(g, e)
    end
<<<<<<< HEAD
<<<<<<< HEAD
    n = nv(g)
    neigs = copy(neighbors(g, n))
>>>>>>> change rem_edge
=======
    neigs = copy(out_neighbors(g, n))
>>>>>>> more work on vertex/edge removal
=======
    neigs = copy(in_neighbors(g, n))
>>>>>>> finish work on vertex removal
    for i in neigs
        unsafe_rem_edge!(g, Edge(i, n))
    end
    if v != n
        for i in neigs
            unsafe_add_edge!(g, Edge(i, v))
        end
<<<<<<< HEAD
    end

    if is_directed(g)
<<<<<<< HEAD
<<<<<<< HEAD
        edgs = out_edges(g, v)
        for e in edgs
            unsafe_rem_edge!(g, e)
        end
        neigs = copy(out_neighbors(g, n))
=======
        edgs = in_edges(g, v)
        for e in edgs
            unsafe_rem_edge!(g, e)
        end
        neigs = copy(in_neighbors(g, n))
>>>>>>> more work on vertex/edge removal
=======
        edgs = out_edges(g, v)
        for e in edgs
            unsafe_rem_edge!(g, e)
        end
        neigs = copy(out_neighbors(g, n))
>>>>>>> finish work on vertex removal
        for i in neigs
            unsafe_rem_edge!(g, Edge(n, i))
        end
        if v != n
            for i in neigs
                unsafe_add_edge!(g, Edge(v, i))
<<<<<<< HEAD
<<<<<<< HEAD
            end
        end
=======
>>>>>>> change rem_edge
=======
        end
            end
>>>>>>> more work on vertex/edge removal
=======
            end
        end
>>>>>>> finish work on vertex removal
    end

    g.vertices = 1:n-1
    pop!(g.fadjlist)
    if is_directed(g)
        pop!(g.badjlist)
    end
    g
end

"""Return the number of edges which start at vertex `v`."""
indegree(g::SimpleGraph, v::Int) = length(badj(g,v))
"""Return the number of edges which end at vertex `v`."""
outdegree(g::SimpleGraph, v::Int) = length(fadj(g,v))


indegree(g::SimpleGraph, v::AbstractArray{Int,1} = vertices(g)) = [indegree(g,x) for x in v]
outdegree(g::SimpleGraph, v::AbstractArray{Int,1} = vertices(g)) = [outdegree(g,x) for x in v]
degree(g::SimpleGraph, v::AbstractArray{Int,1} = vertices(g)) = [degree(g,x) for x in v]

"Return the maxium `outdegree` of vertices in `g`."
Δout(g) = noallocextreme(outdegree,(>), typemin(Int), g)
"Return the minimum `outdegree` of vertices in `g`."
δout(g) = noallocextreme(outdegree,(<), typemax(Int), g)
"Return the maximum `indegree` of vertices in `g`."
δin(g)  = noallocextreme(indegree,(<), typemax(Int), g)
"Return the minimum `indegree` of vertices in `g`."
Δin(g)  = noallocextreme(indegree,(>), typemin(Int), g)
"Return the minimum `degree` of vertices in `g`."
δ(g)    = noallocextreme(degree,(<), typemax(Int), g)
"Return the maximum `degree` of vertices in `g`."
Δ(g)    = noallocextreme(degree,(>), typemin(Int), g)

=={G<:SimpleGraph}(g::G, h::G) = (vertices(g) == vertices(h)) && (edges(g) == edges(h))

"computes the extreme value of `[f(g,i) for i=i:nv(g)]` without gathering them all"
function noallocextreme(f, comparison, initial, g)
    value = initial
    for i in 1:nv(g)
        funci = f(g, i)
        if comparison(funci, value)
            value = funci
        end
    end
    return value
end

"""Produces a histogram of degree values across all vertices for the graph `g`.
The number of histogram buckets is based on the number of vertices in `g`.
"""
degree_histogram(g::SimpleGraph) = (hist(degree(g), 0:nv(g)-1)[2])


"""Returns a list of all neighbors connected to vertex `v` by an incoming edge.

NOTE: returns a reference, not a copy. Do not modify result.
"""
in_neighbors(g::SimpleGraph, v::Int) = badj(g,v)
"""Returns a list of all neighbors connected to vertex `v` by an outgoing edge.

NOTE: returns a reference, not a copy. Do not modify result.
"""
out_neighbors(g::SimpleGraph, v::Int) = fadj(g,v)

"""Returns a list of all neighbors of vertex `v` in `g`.

For DiGraphs, this is equivalent to `out_neighbors(g, v)`.

NOTE: returns a reference, not a copy. Do not modify result.
"""
neighbors(g::SimpleGraph, v::Int) = out_neighbors(g, v)

"Returns the neighbors common to vertices `u` and `v` in `g`."
common_neighbors(g::SimpleGraph, u::Int, v::Int) = intersect(neighbors(g,u), neighbors(g,v))

"Returns true if `g` is has any self loops."
has_self_loop(g::SimpleGraph) = any(v->has_edge(g, v, v), vertices(g))

# internal function that copies the end element to position n within an array
# and then pops the end element, effectively removing element n from the
# array.
function _swapnpop!(a::AbstractArray, n::Int)
    n > length(a) && throw(BoundsError())
    a[n] = a[end]
    pop!(a)
end
