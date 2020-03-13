mutable struct DummyGraph <: AbstractGraph{Int} end
mutable struct DummyDiGraph <: AbstractGraph{Int} end
mutable struct DummyEdge <: AbstractEdge{Int} end

@testset "Interface" begin
    dummygraph = DummyGraph()
    dummydigraph = DummyDiGraph()
    dummyedge = DummyEdge()

    @test_throws LightGraphs.NotImplementedError is_directed(DummyGraph)
    @test_throws LightGraphs.NotImplementedError zero(DummyGraph)

    @test LightGraphs.has_contiguous_vertices(DummyGraph)
    @test LightGraphs.has_contiguous_vertices(DummyDiGraph)
    @test LightGraphs.has_contiguous_vertices(dummygraph)

    LightGraphs.has_contiguous_vertices(::Type{<:DummyGraph}) = false
    @test !LightGraphs.has_contiguous_vertices(DummyGraph)
    @test !LightGraphs.has_contiguous_vertices(dummygraph)

    for edgefun in [src, dst, Pair, Tuple, reverse]
        @test_throws LightGraphs.NotImplementedError edgefun(dummyedge)
    end

    for edgefun2edges in [==]
        @test_throws LightGraphs.NotImplementedError edgefun2edges(dummyedge, dummyedge)
     end

    for graphfunbasic in [
        nv, ne, vertices, edges, is_directed,
        edgetype, eltype
    ]
        @test_throws LightGraphs.NotImplementedError graphfunbasic(dummygraph)
    end

    for graphfun1int in [
        has_vertex, inneighbors, outneighbors
    ]
        @test_throws LightGraphs.NotImplementedError graphfun1int(dummygraph, 1)
    end
    for graphfunedge in [
        has_edge,
      ]
        @test_throws LightGraphs.NotImplementedError graphfunedge(dummygraph, dummyedge)
        @test_throws LightGraphs.NotImplementedError graphfunedge(dummygraph, 1, 2)
    end

    # Implementation error
    impl_error = LightGraphs.NotImplementedError(edges)
    @test impl_error isa LightGraphs.NotImplementedError{typeof(edges)}
    io = IOBuffer()
    Base.showerror(io, impl_error)
    @test String(take!(io)) == "method $edges not implemented."

end # testset


struct FakeGraph <: AbstractGraph{Int} end

LightGraphs.nv(::FakeGraph) = 33

@testset "Test vertices default" begin
    @test vertices(FakeGraph()) == Base.OneTo(33)
    @test has_vertex(FakeGraph(), 22)
end
