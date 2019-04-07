module HenonMap
export henon_map

using Parameters: @with_kw, @unpack
using ..ExampleBase: LEDemo, DiscreteExample

@with_kw struct HenonMapParam
    a::Float64 = 1.4
    b::Float64 = 0.3
end

@inline function phase_dynamics!(u_next, u, p, t)
    @unpack a, b = p
    u_next[1] = 1 + u[2] - a * u[1]^2
    u_next[2] = b * u[1]
end

@inline @views function tangent_dynamics!(u_next, u, p, t)
    @unpack a, b = p
    phase_dynamics!(u_next[:, 1], u[:, 1], p, t)
    u_next[1, 2:end] .= u[2, 2:end] .- a * 2 * u[1, 1] .* u[1, 2:end]
    u_next[2, 2:end] .= b .* u[1, 2:end]
end

"""
Return a [`LEDemo`](@ref) for the Hénon map.

* M. Hénon, Commun. Math. Phys. Phys. 50, 69-77 (1976)
* <http://sprott.physics.wisc.edu/chaos/comchaos.htm>
* <https://en.wikipedia.org/wiki/H%C3%A9non_map>
"""
function henon_map(;
        u0=[-0.3332501594195585, 0.2743725483437717],
        t_renorm=10,
        t_attr=100000,
        atol=0, rtol=1e-2,
        terminator_options = [:atol => atol, :rtol => rtol],
        kwargs...)
    LEDemo(DiscreteExample(
        "Hénon map",
        phase_dynamics!, u0, t_renorm, HenonMapParam(),
        tangent_dynamics!,
        t_attr,
        [0.41922, -1.62319],   # known_exponents
        atol, rtol,
        terminator_options,
    ); kwargs...)
end

end
