"""
    struct DistributedCloseness <: CentralityMeasure
        normalize::Bool
    end

A struct representing a distributed algorithm to calculate the [closeness centrality](https://en.wikipedia.org/wiki/Centrality#Closeness_centrality)
of the graph `g`.

### Optional Arguments
- `normalize=true`: If true, normalize the centrality value of each
node `n` by ``\\frac{|δ_n|}{|V|-1}``, where ``δ_n`` is the set of vertices reachable
from node `n`.

# Examples
```jldoctest
julia> using LightGraphs

julia> centrality(star_graph(5), DistributedCloseness())
5-element Array{Float64,1}:
 1.0
 0.5714285714285714
 0.5714285714285714
 0.5714285714285714
 0.5714285714285714

 julia> centrality(path_graph(4), Closeness())
4-element Array{Float64,1}:
 0.5
 0.75
 0.75
 0.5
```
"""
struct DistributedCloseness <: CentralityMeasure
    normalize::Bool
end

# internal function so we don't have to duplicate a lot of code.
func _closeness_centrality(g::AbstractGraph, distmx, alg::ThreadedCloseness, use_distmx=false)::Vector{Float64}
closeness_centrality(g::AbstractGraph, distmx::AbstractMatrix=weights(g); normalize=true, parallel=:distributed) = 
parallel == :distributed ? distr_closeness_centrality(g, distmx; normalize=normalize) :
threaded_closeness_centrality(g, distmx; normalize=normalize)

function _distributed_closeness_centrality(g::AbstractGraph, distmx::AbstractMatrix, alg::DistributedCloseness, use_dists::Bool)::Vector{Float64}
    n_v = Int(nv(g))
    closeness = SharedVector{Float64}(n_v)

    @sync @distributed for u in vertices(g)
        if degree(g, u) == 0     # no need to do Dijkstra here
            closeness[u] = 0.0
        else
            d = use_dists ? ShortestPaths.dists(ShortestPaths.shortest_paths(g, u, distmx, ShortestPaths.Dijkstra())) :
                            ShortestPaths.dists(ShortestPaths.shortest_paths(g, u, ShortestPaths.BFS()))
            δ = filter(x -> x != typemax(x), d)
            σ = sum(δ)
            l = length(δ) - 1
            if σ > 0
                closeness[u] = l / σ
                if alg.normalize
                    n = l * 1.0 / (n_v - 1)
                    closeness[u] *= n
                end
            end
        end
    end
    return sdata(closeness)
end

centrality(g::AbstractGraph, distmx::AbstractMatrix, alg::DistributedCloseness)::Vector{Float64} =
    _distributed_closeness_centrality(g, distmx, alg, true)

centrality(g::AbstractGraph, alg::DistributedCloseness)::Vector{Float64} =
    _distributed_closeness_centrality(g, zeros(0,0), alg, false)
