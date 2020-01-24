@inline function nop(x...) end

abstract type AbstractTraversalState end

struct DefaultTraversalState <: AbstractTraversalState end

function traverse_graph(
    g::AbstractGraph{U},
    ss::AbstractVector{U},
    alg::BFS;
    initfn::Function = nop,
    previsitfn::Function = nop,
    newvisitfn::Function = nop,
    visitfn::Function = nop,
    postvisitfn::Function = nop,
    postlevelfn::Function = nop,
    state::AbstractTraversalState=DefaultTraversalState(),
    ) where U<:Integer


    n = nv(g)
    visited = falses(n)
    cur_level = Vector{U}()
    sizehint!(cur_level, n)
    next_level = Vector{U}()
    sizehint!(next_level, n)
    @inbounds for s in ss
        visited[s] = true
        push!(cur_level, s)
        initfn(state, s)
    end
    while !isempty(cur_level)
        @inbounds for v in cur_level
            previsitfn(state, v)
            @inbounds @simd for i in outneighbors(g, v)
                if !visited[i]
                    newvisitfn(state, v, i)
                    push!(next_level, i)
                    visited[i] = true
                end
                visitfn(state, v, i)
            end
            postvisitfn(state, v)
        end
        postlevelfn(state)
        empty!(cur_level)
        cur_level, next_level = next_level, cur_level
        sort!(cur_level, alg=alg.sort_alg)
    end
    return state
end

struct VisitState{T<:Integer} <: AbstractTraversalState
    visited::Vector{T}
end

function visited_vertices(
    g::AbstractGraph{U},
    ss::AbstractVector{U},
    alg::BFS
    ) where U<:Integer

    v = Vector{U}()
    sizehint!(v, nv(g))  # actually just the largest connected component, but we'll use this.
    state = VisitState(v)

    @inline initfn!(state, s) = push!(state.visited, s)
    @inline newvisitfn!(state, v, i) = push!(state.visited, i)
    

    traverse_graph(g, ss, BFS(); state=state, newvisitfn=newvisitfn!)

    return state.visited
end

mutable struct BFSSPState{U} <: AbstractTraversalState
    parents::Vector{U}
    dists::Vector{U}
    n_level::U
end

function bfssp(
    g::AbstractGraph{U},
    ss::AbstractVector{U},
    alg::BFS
   ) where U <: Integer

    n = nv(g)
    dists = fill(typemax(U), n)
    parents = zeros(U, n)
    state = BFSSPState(parents, dists, one(U))
    
    @inline initfn!(state, s) = state.dists[s] = 0

    @inline function newvisitfn!(state, v, i)
        state.dists[i] = state.n_level
        state.parents[i] = v
    end

    @inline postlevelfn!(state) = state.n_level += one(U)

    traverse_graph(g, ss, BFS(); state=state, initfn = initfn!, newvisitfn=newvisitfn!, postlevelfn = postlevelfn!)
    return BFSResult(state.parents, state.dists)
end
