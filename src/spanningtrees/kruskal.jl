"""
    kruskal_mst(g, distmx=weights(g))
Return a vector of edges representing the minimum spanning tree of a connected, undirected graph `g` with optional
distance matrix `distmx` using [Kruskal's algorithm](https://en.wikipedia.org/wiki/Kruskal%27s_algorithm).
"""
function kruskal_mst end
# see https://github.com/mauro3/SimpleTraits.jl/issues/47#issuecomment-327880153 for syntax
@traitfn function kruskal_mst(g::AG::(!IsDirected),  edge_list::Vector{Edge{U}},
    distmx::AbstractMatrix{T}=weights(g)) where {T <: Real, U, AG <: AbstractGraph{U}}

    connected_vs = IntDisjointSets(nv(g))

    mst = Vector{Edge}()
    sizehint!(mst, nv(g) - 1)

    #=
    weights = Vector{T}()
    sizehint!(weights, ne(g))
    edge_list = collect(edges(g))
    for e in edge_list
        push!(weights, distmx[src(e), dst(e)])
    end
    edge_list = edge_list[sortperm(weights)]
    =#

    for e in edge_list
        if !in_same_set(connected_vs, e.src, e.dst)
            union!(connected_vs, e.src, e.dst)
            push!(mst, e)
            (length(mst) >= nv(g) - 1) && break
        end
    end

    return mst
end
