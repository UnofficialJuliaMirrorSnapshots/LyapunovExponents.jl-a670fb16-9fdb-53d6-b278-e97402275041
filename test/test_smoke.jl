using Base.Test
using Plots
using OnlineStats: CovMatrix
using LyapunovExponents
using LyapunovExponents: VecVariance, with_input_noise, with_output_noise
using LyapunovExponents.TestTools: @test_nothrow

@time @testset "Smoke test CLV" begin
    @test_nothrow begin
        prob = LyapunovExponents.lorenz_63(t_attr=3).prob :: LEProblem
        solver = CLVSolver(prob)
        solve!(solver)
    end
    @testset "Recording CLV" begin
        prob = LyapunovExponents.lorenz_63(t_attr=3).prob :: LEProblem
        solver = CLVSolver(
            prob;
            record = [:G, :C, :D, :x])
        solve!(solver)
        @test isdefined(solver.sol, :G_history)
        @test isdefined(solver.sol, :C_history)
        @test isdefined(solver.sol, :D_history)
        @test isdefined(solver.sol, :x_history)
        @test unique(size.(solver.sol.G_history)) == [(3, 3)]
        @test unique(size.(solver.sol.C_history)) == [(3, 3)]
        @test unique(size.(solver.sol.D_history)) == [(3,)]
        @test unique(size.(solver.sol.x_history)) == [(3,)]
    end
end

@time @testset "Smoke test demo" begin
    @test begin
        demo = solve!(LyapunovExponents.lorenz_63(t_attr=3))
        plot(demo, show = false)
        true
    end
    @test begin
        demo = solve!(LyapunovExponents.lorenz_63(t_attr=3, dim_lyap=1))
        plot(demo, show = false)
        true
    end
    @testset "main_stat = $ST" for ST in [VecVariance, CovMatrix]
        demo = LyapunovExponents.lorenz_63(t_attr=3)
        @test_nothrow solve!(demo; main_stat = ST)
        sol = demo.solver.sol
        @test isa(sol.main_stat, ST)
        @test_nothrow plot(demo, show = false)
    end
end

@time @testset "Smoke test RODE" begin
    ode = LyapunovExponents.lorenz_63().prob.phase_prob
    rode = with_input_noise(ode, 1)
    @test_nothrow begin
        t_attr = 3
        prob = LEProblem(rode; t_attr=t_attr)
        sol = solve(prob; record=true, integrator_options=[:dt => 1e-3])
        plot(sol)
    end

    rode = with_output_noise(ode, 1)
    @test_nothrow begin
        t_attr = 3
        prob = LEProblem(rode; t_attr=t_attr)
        sol = solve(prob; record=true, integrator_options=[:dt => 1e-3])
        plot(sol)
    end
end
