export time_type, phase_type, equation_type, state_vectors

"""
    time_type(solver)

Retrieve the `TimeType` associated with `solver`. Override this method for
custom solver types if the information lives somewhere other than
`solver.time_type`.
"""
time_type(solver) = getproperty(solver, :time_type)

"""
    phase_type(solver)

Retrieve the `PhaseType` associated with `solver`. Defaults to the
`solver.phase_type` field.
"""
phase_type(solver) = getproperty(solver, :phase_type)

"""
    equation_type(solver)

Retrieve the `EquationType` associated with `solver`. If the solver does not
define the field, `Diffusion` is assumed to preserve backwards compatibility
with the legacy Penguin solver implementation.
"""
function equation_type(solver)
    if hasproperty(solver, :equation_type)
        return getproperty(solver, :equation_type)
    end
    return Diffusion
end

"""
    state_vectors(solver)

Return an iterable of state vectors to be written to disk. Steady simulations
emit a single-element tuple, while unsteady simulations return the
`solver.states` collection verbatim. Extend this method for solvers that store
state history differently.
"""
function state_vectors(solver)
    tt = time_type(solver)
    if tt == Steady
        state = getproperty(solver, :x)
        return (state,)
    end
    return getproperty(solver, :states)
end
