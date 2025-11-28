using Test
using VTKOutputs

import VTKOutputs: mesh_axes, mesh_shape, build_fields, default_field_names
using VTKOutputs: Steady, Unsteady, Monophasic, Diphasic, Diffusion
using VTKOutputs: time_type, phase_type, equation_type

struct DummyMesh
    centers::Vector{Vector{Float64}}
end

struct DummySolver
    time_type::TimeType
    phase_type::PhaseType
    equation_type::EquationType
    x::Vector{Float64}
    states::Vector{Vector{Float64}}
end

DummySolver(; time_type, phase_type, equation_type = Diffusion, x = Float64[], states = Vector{Vector{Float64}}()) =
    DummySolver(time_type, phase_type, equation_type, x, states)

module ForeignEnums
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
end

struct ForeignSolver
    time_type::ForeignEnums.TimeType
    phase_type::ForeignEnums.PhaseType
    equation_type::ForeignEnums.EquationType
    x::Vector{Float64}
    states::Vector{Vector{Float64}}
end

ForeignSolver(; time_type, phase_type, equation_type = ForeignEnums.Diffusion, x = Float64[], states = Vector{Vector{Float64}}()) =
    ForeignSolver(time_type, phase_type, equation_type, x, states)

@testset "Mesh helpers" begin
    centers = [collect(1:3), collect(1:2)]
    mesh = DummyMesh(centers)
    axes = mesh_axes(mesh)
    dims = mesh_shape(mesh)
    @test length(axes) == 2
    @test dims == (length(centers[1]) + 1, length(centers[2]) + 1)
end

@testset "Field construction" begin
    mesh_dims = (5,)
    state = collect(1.0:10.0)

    default_names = default_field_names("", Monophasic)
    fields = build_fields(state, mesh_dims, Monophasic; field_prefix = "")
    @test length(fields) == length(default_names)
    @test all(first(f) in default_names for f in fields)
    @test size(last(fields[1])) == mesh_dims

    prefixed_names = default_field_names("Temperature", Monophasic)
    prefixed_fields = build_fields(state, mesh_dims, Monophasic; field_prefix = "Temperature")
    @test all(first(f) in prefixed_names for f in prefixed_fields)
end

@testset "Enum coercion" begin
    mesh_dims = (5,)
    state = collect(1.0:10.0)
    foreign = ForeignSolver(
        time_type = ForeignEnums.Steady,
        phase_type = ForeignEnums.Monophasic,
        equation_type = ForeignEnums.Diffusion,
        x = state,
        states = Vector{Vector{Float64}}(),
    )

    @test time_type(foreign) == Steady
    @test phase_type(foreign) == Monophasic
    @test equation_type(foreign) == Diffusion

    tmp = mktempdir()
    base = joinpath(tmp, "foreign_case")
    mesh = DummyMesh([collect(1:4)])
    write_vtk(base, mesh, foreign)
    @test isfile(string(base, ".vti"))
end

@testset "VTK writing" begin
    tmp = mktempdir()

    mono_mesh = DummyMesh([collect(1:4)])
    mono_solver = DummySolver(time_type = Steady, phase_type = Monophasic, x = collect(1.0:10.0))
    steady_base = joinpath(tmp, "steady_case")
    write_vtk(steady_base, mono_mesh, mono_solver)
    @test isfile(string(steady_base, ".vti"))

    foreign_solver = ForeignSolver(time_type = ForeignEnums.Steady, phase_type = ForeignEnums.Monophasic, x = collect(1.0:10.0))
    foreign_base = joinpath(tmp, "foreign_case_vtk")
    write_vtk(foreign_base, mono_mesh, foreign_solver)
    @test isfile(string(foreign_base, ".vti"))

    dip_mesh = DummyMesh([collect(1:2), collect(1:1)])
    state_len = prod(mesh_shape(dip_mesh)) * length(default_field_names("", Diphasic))
    state1 = collect(1.0:state_len)
    state2 = state1 .* 2
    dip_solver = DummySolver(time_type = Unsteady, phase_type = Diphasic, states = [state1, state2])
    transient_base = joinpath(tmp, "transient_case")
    write_vtk(transient_base, dip_mesh, dip_solver)
    @test isfile(string(transient_base, ".pvd"))
end
