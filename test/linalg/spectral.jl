import Base: full

# just so that we can assert equality of matrices
full(nbt::Nonbacktracking) = full(sparse(nbt))

@testset "Spectral" begin

    g3 = PathGraph(5)
    g4 = PathDiGraph(5)
    g5 = DiGraph(4)
    for g in testgraphs(g3)
      @test @inferred(adjacency_matrix(g)[3,2]) == 1
      @test @inferred(adjacency_matrix(g)[2,4]) == 0
      @test @inferred(laplacian_matrix(g)[3,2]) == -1
      @test @inferred(laplacian_matrix(g)[1,3]) == 0
      @test @inferred(laplacian_spectrum(g)[5]) == 3.6180339887498945
      @test @inferred(adjacency_spectrum(g)[1]) == -1.732050807568878
    end


    add_edge!(g5,1,2); add_edge!(g5,2,3); add_edge!(g5,1,3); add_edge!(g5,3,4)
    for g in testdigraphs(g5)
      @test @inferred(laplacian_spectrum(g)[3]) == laplacian_spectrum(g,:both)[3] == 3.0
      @test @inferred(laplacian_spectrum(g,:in)[3]) == 1.0
      @test @inferred(laplacian_spectrum(g,:out)[3]) == 1.0
    end

    # check adjacency matrices with self loops
    gx = copy(g3)
    add_edge!(gx,1,1)
    for g in testgraphs(gx)
      @test @inferred(adjacency_matrix(g)[1,1]) == 2
    end

    g10 = CompleteGraph(10)
    for g in testgraphs(g10)
      B, em = non_backtracking_matrix(g)
      @test @inferred(length(em)) == 2*ne(g)
      @test @inferred(size(B)) == (2*ne(g),2*ne(g))
      for i=1:10
          @test @inferred(sum(B[:,i])) == 8
          @test @inferred(sum(B[i,:])) == 8
      end
      @test !issymmetric(B)

      v = ones(Float64, ne(g))
      z = zeros(Float64, nv(g))
      n10 = Nonbacktracking(g)
      @test @inferred(size(n10)) == (2*ne(g), 2*ne(g))
      @test @inferred(eltype(n10)) == Float64
      @test !issymmetric(n10)

      LightGraphs.contract!(z, n10, v)

      zprime = contract(n10, v)
      @test z == zprime
      @test z == 9*ones(Float64, nv(g))
    end

    for g in testdigraphs(g5)
        @test (adjacency_spectrum(g))[3] ≈ 0.311 atol=0.001
    end

    for g in testgraphs(g3)
      @test @inferred(adjacency_matrix(g)) ==
        adjacency_matrix(g, :out) ==
        adjacency_matrix(g, :in) ==
        adjacency_matrix(g, :both)

      @test_throws ErrorException adjacency_matrix(g, :purple)
    end

    #that call signature works
    for g in testdigraphs(g5)
      inmat   = adjacency_matrix(g, :in, Int)
      outmat  = adjacency_matrix(g, :out, Int)
      bothmat = adjacency_matrix(g, :both, Int)

    #relations that should be true
      @test @inferred(inmat') == outmat
      @test all((bothmat - outmat) .>= 0)
      @test all((bothmat - inmat)  .>= 0)

      #check properties of the undirected laplacian carry over.
      for dir in [:in, :out, :both]
        amat = adjacency_matrix(g, dir, Float64)
        lmat = laplacian_matrix(g, dir, Float64)
        @test isa(amat, SparseMatrixCSC{Float64, Int64})
        @test isa(lmat, SparseMatrixCSC{Float64, Int64})
        evals = eigvals(full(lmat))
        @test all(evals .>= -1e-15) # positive semidefinite
        @test (minimum(evals)) ≈ 0 atol=1e-13
      end
    end


    for g in testdigraphs(g4)
    # testing incidence_matrix, first directed graph
      @test @inferred(size(incidence_matrix(g))) == (5,4)
      @test @inferred(incidence_matrix(g)[1,1]) == -1
      @test @inferred(incidence_matrix(g)[2,1]) == 1
      @test @inferred(incidence_matrix(g)[3,1]) == 0
    end

    for g in testgraphs(g3)
    # now undirected graph
      @test @inferred(size(incidence_matrix(g))) == (5,4)
      @test @inferred(incidence_matrix(g)[1,1]) == 1
      @test @inferred(incidence_matrix(g)[2,1]) == 1
      @test @inferred(incidence_matrix(g)[3,1]) == 0

    # undirected graph with orientation
      @test size(incidence_matrix(g; oriented=true)) == (5,4)
      @test incidence_matrix(g; oriented=true)[1,1] == -1
      @test incidence_matrix(g; oriented=true)[2,1] == 1
      @test incidence_matrix(g; oriented=true)[3,1] == 0
    end
    # TESTS FOR Nonbacktracking operator.

    n = 10; k = 5
    pg = CompleteGraph(n)
    # ϕ1 = nonbacktrack_embedding(pg, k)'
    for g in testgraphs(pg)
      nbt = Nonbacktracking(g)
      B, emap = non_backtracking_matrix(g)
      Bs = sparse(nbt)
      @test @inferred(sparse(B)) == Bs
      @test eigs(nbt, nev=1)[1] ≈ eigs(B, nev=1)[1] atol=1e-5

      # check that matvec works
      x = ones(Float64, nbt.m)
      y = nbt * x
      z = B * x
      @test norm(y-z) < 1e-8

      #check that matmat works and full(nbt) == B
      @test norm(nbt*eye(nbt.m) - B) < 1e-8

      #check that matmat works and full(nbt) == B
      @test norm(nbt*eye(nbt.m) - B) < 1e-8

      #check that we can use the implicit matvec in nonbacktrack_embedding
      @test @inferred(size(y)) == size(x)

      B₁ = Nonbacktracking(g10)

      @test @inferred(full(B₁)) == full(B)
      @test  B₁ * ones(size(B₁)[2]) == B*ones(size(B)[2])
      @test @inferred(size(B₁)) == size(B)
    #   @test norm(eigs(B₁)[1] - eigs(B)[1]) ≈ 0.0 atol=1e-8
      @test !issymmetric(B₁)
      @test @inferred(eltype(B₁)) == Float64
    end
    # END tests for Nonbacktracking

    # spectral distance checks
    for n=3:10
      polygon = random_regular_graph(n, 2)
      for g in testgraphs(polygon)
        @test isapprox(spectral_distance(g, g), 0, atol=1e-8)
        @test isapprox(spectral_distance(g, g, 1), 0, atol=1e-8)
      end
    end
end
