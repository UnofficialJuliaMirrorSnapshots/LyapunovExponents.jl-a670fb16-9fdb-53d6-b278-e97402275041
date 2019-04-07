module TestNullCLV

using Base.Test
using Parameters: @with_kw, @unpack
using LyapunovExponents
using LyapunovExponents.Stages: is_finished
using LyapunovExponents: DEMOS, LEDemo, dimension, is_semi_unitary

@with_kw struct NullCLVTest
    name::String
    prob::CLVProblem
    tolerance::Float64
    err_rate::Float64
end

NullCLVTest(demo::LEDemo;
            tolerance = nothing,
            err_rate = 0.0,
            kwargs...) = NullCLVTest(
    name = demo.example.name,
    prob = CLVProblem(demo.prob; kwargs...),
    tolerance = tolerance,
    err_rate = err_rate,
)

null_CLV_tests = [
    NullCLVTest(LyapunovExponents.lorenz_63();
                t_clv = 20000,
                t_forward_tran = 4000,
                t_backward_tran = 4000,
                err_rate = 0.004,
                tolerance = 1e-2),
    # linz_sprott_99() requires a small `tspan` to make `tolerance`
    # smaller.
    NullCLVTest(LyapunovExponents.linz_sprott_99(t_renorm=0.1);
                t_clv = 2000,
                t_forward_tran = 4000,
                t_backward_tran = 4000,
                err_rate = 0.2,
                tolerance = 0.2),  # TODO: minimize
    NullCLVTest(LyapunovExponents.beer_95();
                t_clv = 2000,
                t_forward_tran = 1000,
                t_backward_tran = 1000,
                err_rate = 0.05,
                tolerance = 1e-2),
]

@time @testset "Null CLV: $(test.name)" for test in null_CLV_tests
    @unpack prob, tolerance, err_rate = test

    solver = init(prob; record=[:G, :C, :x])
    solve!(solver)

    Q0 = @view prob.tangent_prob.u0[:, 2:end]
    dims = size(Q0)
    x = solver.sol.x_history
    G = solver.sol.G_history
    C = solver.sol.C_history
    num_clv = ceil(Int, prob.t_clv / prob.t_renorm)
    @test_broken length(x) == num_clv
    @test_broken length(G) == num_clv
    @test length(C) == num_clv
    @test all(norm(Cₙ[:, i]) ≈ 1 for Cₙ in C for i in 1:size(Cₙ, 2))
    @test all(map(is_semi_unitary, G))

    function ∂ₜ(u, prob = prob.phase_prob, t = 0.0)
        du = similar(u)
        prob.f(du, u, prob.p, t)
        return du
    end

    angles = collect(
        let ∂ₜxₙ = ∂ₜ(x[n]),
            vₙ = G[n] * C[n][:, 2]
            acos(abs(∂ₜxₙ' * vₙ) / norm(∂ₜxₙ))
        end
        for n in 1:num_clv)

    @test mean(angles .> tolerance) <= err_rate

end

end
