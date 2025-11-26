export write_vtk

const MONO_FIELD_NAMES = ("Bulk Field", "Interface Field")
const DI_FIELD_NAMES = (
	"Bulk Field 1",
	"Interface Field 1",
	"Bulk Field 2",
	"Interface Field 2",
)

function write_vtk(
	filename::AbstractString,
	mesh,
	solver;
	field_prefix::AbstractString = "",
	digits::Integer = 3,
)
	axes = mesh_axes(mesh)
	dims = mesh_shape(mesh)
	nd = length(axes)
	1 <= nd <= 3 || error("WriteVTK only supports 1D, 2D, or 3D grids (got $nd)")

	tt = time_type(solver)
	ph = phase_type(solver)
	et = equation_type(solver)
	states = collect(state_vectors(solver))
	isempty(states) && error("Solver provided no states to export")

	ph in (Monophasic, Diphasic) || error("Unsupported phase type $(ph)")
	et in (Diffusion, Advection, DiffusionAdvection) || error("Unsupported equation type $(et)")

	field_names = default_field_names(field_prefix, ph)

	if tt == Steady
		vtk = write_single_state(filename, axes, dims, first(states), ph; field_prefix)
		@info "VTK steady file written" path = string(filename, ".vti") fields = field_names
		return vtk
	else
		pvd = paraview_collection(filename)
		for (i, state) in enumerate(states)
			state_name = string(filename, "_", lpad(i, digits, '0'))
			pvd[i] = write_single_state(state_name, axes, dims, state, ph; field_prefix)
		end
		vtk_save(pvd)
		@info "VTK time collection written" path = string(filename, ".pvd") states = length(states) fields = field_names
		return pvd
	end
end

function write_single_state(name, axes, dims, state, phase_type; field_prefix)
	fields = build_fields(state, dims, phase_type; field_prefix)
	vtk = vtk_grid(name, axes...)
	for (field_name, array) in fields
		vtk[field_name] = array
	end
	vtk_save(vtk)
	return vtk
end

function build_fields(state, dims, phase_type; field_prefix)
	names = default_field_names(field_prefix, phase_type)
	state_vec = vec(state)
	nfields = length(names)
	len = length(state_vec)
	block = div(len, nfields)
	block * nfields == len || error("State vector length $(len) not divisible by number of fields $(nfields)")

	expected = prod(dims)
	expected == block || error("State block length $(block) does not match mesh shape $(expected)")

	fields = Vector{Pair{String, AbstractArray}}(undef, nfields)
	start_idx = 1
	for (i, field_name) in enumerate(names)
		stop_idx = start_idx + block - 1
		slice = view(state_vec, start_idx:stop_idx)
		fields[i] = field_name => reshape(slice, dims...)
		start_idx = stop_idx + 1
	end
	return fields
end

function default_field_names(prefix::AbstractString, phase_type)
	base = phase_type == Monophasic ? MONO_FIELD_NAMES : DI_FIELD_NAMES
	if isempty(prefix)
		return base
	end
	return Tuple(string(prefix, " ", name) for name in base)
end
