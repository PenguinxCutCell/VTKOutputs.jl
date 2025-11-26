export TimeType, PhaseType, EquationType

@enum TimeType begin
    Steady
    Unsteady
end

@enum PhaseType begin
    Monophasic
    Diphasic
end

@enum EquationType begin
    Diffusion
    Advection
    DiffusionAdvection
end
