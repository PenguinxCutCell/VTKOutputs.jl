# VTKOutputs.jl

Lightweight utilities for exporting Penguin solver results (or any solver with
a compatible interface) to `.vti` and `.pvd` files through
[WriteVTK.jl](https://github.com/jipolanco/WriteVTK.jl). The package focuses on
templating the repetitive logic needed for steady/unsteady and mono/diphasic
runs, so the solver can stay clean.

## Installation

```julia
pkg> add https://github.com/PenguinxCutCell/VTKOutputs.jl
```

## Supported solver interface

`write_vtk(filename, mesh, solver)` operates on duck-typed inputs. Out of the
box it expects the following fields (or trait overloads):

- `mesh.centers` – tuple/vector of axis center coordinates (one entry per
	dimension).
- `solver.time_type::TimeType` – `Steady` or `Unsteady`.
- `solver.phase_type::PhaseType` – `Monophasic` or `Diphasic`.
- `solver.equation_type::EquationType` – currently for validation only.
- `solver.x` – flattened steady-state vector (used when `time_type == Steady`).
- `solver.states` – collection of flattened vectors (used when
	`time_type == Unsteady`).

Override `time_type(::MySolver)`, `phase_type(::MySolver)`, etc. if the data
live behind getters instead of fields.

If your solver already defines its own enums (e.g. `Penguin.Monophasic`), they
are automatically coerced into `VTKOutputs`' enums as long as the ordering or
names match. For bespoke naming schemes, override the trait functions above to
return the corresponding `VTKOutputs.TimeType`/`PhaseType`/`EquationType`.

## Quick start

```julia
using VTKOutputs

mesh = (; centers = [collect(range(0, stop = 0.1, length = 16))])
solver = (
		time_type = Steady,
		phase_type = Monophasic,
		equation_type = Diffusion,
		x = collect(range(250.0, stop = 350.0, length = 32)),
		states = Vector{Vector{Float64}}(),
)

write_vtk("output/temperature", mesh, solver)
```

`write_vtk` automatically selects between single-file `.vti` dumps for steady
cases and a ParaView collection (`.pvd`) when transient states are provided. By
default the exported arrays are named `Bulk Field`/`Interface Field` for
monophasic runs (and `Bulk Field 1`, `Interface Field 1`, ... for diphasic
cases). Provide `field_prefix = "Temperature"` (or any string) if you would
like the names to be prefixed, e.g. `Temperature Bulk Field`.

## Development

- `julia --project -e 'using Pkg; Pkg.test()'`
- Tests stand up throwaway meshes/solvers to ensure the splitting logic keeps
	working.
