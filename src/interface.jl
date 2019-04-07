"""
    lyapunov_exponents(phase_dynamics!, u0, tspan; <keyword arguments>)

Calculate Lyapunov exponents of a dynamical system.
"""
function lyapunov_exponents(phase_dynamics!,
                            u0,
                            tspan,
                            t_attr::Integer;
                            discrete=false,
                            progress=-1,
                            kwargs...)
    if discrete
        prob = ContinuousLEProblem(phase_dynamics!, u0, tspan, kwargs...)
    else
        prob = DiscreteLEProblem(phase_dynamics!, u0, tspan, kwargs...)
    end
    solver = init(prob; progress=progress)
    solve!(solver, t_attr; progress=progress)
    lyapunov_exponents(solver)
end

de_prob(stage::Union{PhaseRelaxer, AbstractRenormalizer}) =
    de_prob(stage.integrator)
de_prob(integrator::DiscreteIterator) = integrator.prob
de_prob(integrator::ODEIntegrator) = integrator.sol.prob
