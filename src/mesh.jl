export VTKMesh, centers_tuple, mesh_axes, mesh_shape

struct VTKMesh{N, T}
    centers::NTuple{N, Vector{T}}
end

function VTKMesh(centers::AbstractVector{<:AbstractVector})
    nt = Tuple(Vector.(centers))
    return VTKMesh{length(nt), eltype(first(nt))}(nt)
end

centers_tuple(mesh::VTKMesh) = mesh.centers

function centers_tuple(mesh)
    centers = getproperty(mesh, :centers)
    return centers isa Tuple ? centers : Tuple(centers)
end

mesh_axes(mesh) = map(c -> 0:1:length(c), centers_tuple(mesh))

mesh_shape(mesh) = map(c -> length(c) + 1, centers_tuple(mesh))
