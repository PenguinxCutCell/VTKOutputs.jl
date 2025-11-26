module VTKOutputs

using WriteVTK

export TimeType, PhaseType, EquationType
export VTKMesh, centers_tuple, mesh_axes, mesh_shape
export time_type, phase_type, equation_type, state_vectors
export write_vtk

include("types.jl")
include("state.jl")
include("mesh.jl")
include("writer.jl")

end
