report(x) = report(STDOUT, x)

function report(io::IO, solver::LESolver; kwargs...)
    report(io, solver.sol; kwargs...)
end

function report(io::IO, sol::LESolution;
                convergence::Bool = true)
    LEs = lyapunov_exponents(sol)

    print_with_color(:blue, io, "Lyapunov Exponents Solution")
    if sol.converged
        print_with_color(:green, io, " (converged)")
    else
        print_with_color(:red, io, " (NOT converged)")
    end
    println(io)

    table = [
        ("#Orth.", sol.num_orth),
        ("#LEs", length(LEs)),
        ("LEs", LEs),
    ]
    for (name, value) in table
        print_with_color(:yellow, io, name)
        print(io, ": ")
        if value isa String
            print(io, value)
        else
            show(IOContext(io, :limit => true), value)
        end
        println(io)
    end

    if convergence
        report(io, sol.convergence)
    end
end

function report(io::IO, convergence::ConvergenceHistory;
                dim_lyap = min(10, length(convergence.errors)))

    if isempty(convergence.orth)
        print_with_color(:red, io, "NO convergence test is done!", bold=true)
        println(io)
        return
    end

    print_with_color(:blue, io, "Convergence")
    print(io, " #Orth.=$(convergence.orth[end])")
    print(io, " #Checks=$(length(convergence.orth))")
    if convergence.kinds[end] == UnstableConvError
        print(io, " [unstable]")
    else
        print(io, " [stable]")
    end
    println(io)

    if length(convergence.kinds) > 1
        print_with_color(:yellow, io, "Stability")
        print(io, ": ")
        for k in convergence.kinds
            if k == UnstableConvError
                print(io, "x")
            else
                print(io, ".")
            end
        end
        println(io)
    end

    print(io, " "^(length("LE$dim_lyap")), "  ",
          "      error", "   ",
          "  threshold")
    if convergence.kinds[end] == UnstableConvError
        print(io,
              "   variance",
              "   tail cov",
              " small tail?")
    end
    println(io)

    for i in 1:dim_lyap
        err = convergence.errors[i][end]
        th = convergence.thresholds[i][end]

        print(io, "LE$i")
        print(io, ": ")
        @printf(io, " %10.5g", err)
        if err < th
            print_with_color(:green, io, " < ")
        else
            print_with_color(:red, io, " > ")
        end
        @printf(io, " %10.5g", th)

        detail = convergence.details[i][end]
        if convergence.kinds[end] == UnstableConvError
            @printf(io, " %10.5g", detail.var)
            @printf(io, " %10.5g", detail.tail_cov)
            print(io, "  ")
            if detail.tail_ok
                print_with_color(:green, io, "yes")
            else
                print_with_color(:red, io, "no")
            end
        else
            print(io, "  ")
            compact_report(io, detail)
        end

        println(io)
    end
end

compact_report(io, _) = nothing
compact_report(io, ::FixedPointConvDetail) =
    print(io, "\"period\" < 1")
compact_report(io, detail::PeriodicConvDetail) =
    print(io, "\"period\": ", detail.period)
compact_report(io, ::NonNegativeAutoCovConvDetail) =
    print(io, "too short (NN)")
compact_report(io, ::NonPeriodicConvDetail) =
    print(io, "too short (NP)")
