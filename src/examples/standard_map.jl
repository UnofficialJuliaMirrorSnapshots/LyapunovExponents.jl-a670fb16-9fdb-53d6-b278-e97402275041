module StandardMap
export standard_map
using ..ExampleBase: LEDemo, DiscreteExample

@inline function phase_dynamics!(u_next, u, k, t)
    u_next[2] = (u[2] + k * sin(u[1])) % 2π
    u_next[1] = (u[1] + u_next[2]) % 2π
end

@inline @views function tangent_dynamics!(u_next, u, k, t)
    phase_dynamics!(u_next[:, 1], u[:, 1], k, t)
    u_next[2, 2:end] .= u[2, 2:end] .+ k * cos(u[1, 1]) .* u[1, 2:end]
    u_next[1, 2:end] .= u[1, 2:end] .+ u_next[2, 2:end]
end

"""
Return a [`LEDemo`](@ref) for the Chirikov standard map.

* B. V. Chirikov, Physics Reports 52, 263-379 (1979)
* <http://sprott.physics.wisc.edu/chaos/comchaos.htm>
* <https://en.wikipedia.org/wiki/Standard_map>
* <http://www.scholarpedia.org/article/Chirikov_standard_map>
"""
function standard_map(;
        u0=[2.68156, 2.31167],
        t_renorm=10,
        t_attr=1000000,
        atol=0, rtol=0.01,
        terminator_options = [:atol => atol, :rtol => rtol,
                              :max_tail_corr => rtol,
                              :first_check => 10000],
        kwargs...)
    # TODO: Improve the accuracy. Check the paper.  It looks like
    # `t_attr=1000000` is required to see some kind of convergence.
    k = 1
    LEDemo(DiscreteExample(
        "Chirikov standard map",
        phase_dynamics!, u0, t_renorm, k,
        tangent_dynamics!,
        t_attr,
        [0.10497, -0.10497],   # known_exponents
        atol, rtol,
        terminator_options,
    ); kwargs...)
end

end
