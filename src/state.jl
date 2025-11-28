export time_type, phase_type, equation_type, state_vectors

const _coercible_enum_error = "Cannot coerce provided value to requested enum; override VTKOutputs.time_type/phase_type/equation_type for custom solver types."

function _coerce_enum(::Type{T}, value) where {T<:Enum}
    value isa T && return value
    try
        if value isa Enum
            return T(Int(value))
        elseif value isa Integer
            return T(value)
        elseif value isa AbstractString
            return T(Symbol(value))
        elseif value isa Symbol
            return T(value)
        end
    catch err
        if err isa ArgumentError || err isa DomainError || err isa InexactError
            throw(ArgumentError(_coercible_enum_error))
        end
        rethrow()
    end
    throw(ArgumentError(_coercible_enum_error))
end

"""
    time_type(solver)

Retrieve the `TimeType` associated with `solver`. The default implementation
attempts to coerce field values such as integers, strings, or foreign enums
into the local `TimeType`. Override this method if your solver stores the
information elsewhere.
"""
time_type(solver) = _coerce_enum(TimeType, getproperty(solver, :time_type))

"""
    phase_type(solver)

Retrieve the `PhaseType` associated with `solver`. Defaults to coercing the
`solver.phase_type` field into the package's `PhaseType` definition.
"""
phase_type(solver) = _coerce_enum(PhaseType, getproperty(solver, :phase_type))

"""
    equation_type(solver)

Retrieve the `EquationType` associated with `solver`. If the solver does not
define the field, `Diffusion` is assumed to preserve backwards compatibility
with the legacy Penguin solver implementation.
"""
function equation_type(solver)
    if hasproperty(solver, :equation_type)
        return _coerce_enum(EquationType, getproperty(solver, :equation_type))
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
