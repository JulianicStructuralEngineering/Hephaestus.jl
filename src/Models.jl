"""
    Model

A type that represents the finite element model of a structure.

To create a model, use the [`Model()`](@ref) constructor.

# Fields
$(FIELDS)
"""
@kwdef mutable struct Model
    "Dictionary of nodes in the model."
    nodes               ::OrderedDict{Int, Node    } = OrderedDict{Int, Node    }()
    "Dictionary of materials in the model."
    materials           ::OrderedDict{Int, Material} = OrderedDict{Int, Material}()
    "Dictionary of sections in the model."
    sections            ::OrderedDict{Int, Section } = OrderedDict{Int, Section }()
    "Dictionary of elements in the model."
    elements            ::OrderedDict{Int, Element } = OrderedDict{Int, Element }()

    "Dictionary of supports in the model."
    supports            ::OrderedDict{Int, Vector{Bool}} = OrderedDict{Int, Vector{Bool}}()

    "Dictionary of concetrated loads (acting on nodes) in the model."
    concetrated_loads   ::OrderedDict{Int, Vector{<:Real}} = OrderedDict{Int, Vector{<:Real}}()
    "Dictionary of distributed loads (acting on elements) in the model."
    distributed_loads   ::OrderedDict{Int, Vector{<:Real}} = OrderedDict{Int, Vector{<:Real}}()
end

function Base.show(io::IO, model::Model)
    if isempty(model.nodes) && isempty(model.materials) && isempty(model.sections) && isempty(model.elements)
        println(io, styled"{yellow, bold: Empty model.}")
    else
        println(io, styled"{cyan, bold: Model with:}")
        !isempty(model.nodes            ) && println(io, styled"{cyan: \t $(length(model.nodes            )) \t Nodes          }")
        !isempty(model.materials        ) && println(io, styled"{cyan: \t $(length(model.materials        )) \t Materials      }")
        !isempty(model.sections         ) && println(io, styled"{cyan: \t $(length(model.sections         )) \t Sections       }")
        !isempty(model.elements         ) && println(io, styled"{cyan: \t $(length(model.elements         )) \t Elements       }")
        !isempty(model.supports         ) && println(io, styled"{cyan: \t $(length(model.supports         )) \t Supported nodes}")
        !isempty(model.concetrated_loads) && println(io, styled"{cyan: \t $(length(model.concetrated_loads)) \t Loaded nodes   }")
        !isempty(model.distributed_loads) && println(io, styled"{cyan: \t $(length(model.distributed_loads)) \t Loaded elements}")
    end
end

function add_node!(model::Model, ID::Int, x::Real, y::Real, z::Real)
    # Check if the node already exists in the model:
    if haskey(model.nodes, ID)
        @warn "Node with ID = $(ID) already exists in the model. Overwriting it."
    end

    # Add the node to the model:
    model.nodes[ID] = Node(ID, 
        x, y, z)

    # Return the updated model:
    return model
end

function add_material!(model::Model, ID::Int, E::Real, ν::Real, ρ::Real)
    # Check if the material already exists in the model:
    if haskey(model.materials, ID)
        @warn "Material with ID = $(ID) already exists in the model. Overwriting it."
    end

    # Add the material to the model:
    model.materials[ID] = Material(ID, 
        E, ν, ρ)

    # Return the updated model:
    return model
end

function add_section!(model::Model, ID::Int, A::Real, I_zz::Real, I_yy::Real, J::Real)
    # Check if the section already exists in the model:
    if haskey(model.sections, ID)
        @warn "Section with ID = $(ID) already exists in the model. Overwriting it."
    end

    # Add the section to the model:
    model.sections[ID] = Section(ID, 
        A, I_zz, I_yy, J)

    # Return the updated model:
    return model
end

function add_element!(model::Model, ID::Int, node_i_ID::Int, node_j_ID::Int, material_ID::Int, section_ID::Int; ω::Real = 0, releases::Vector{Bool} = [false, false, false, false, false, false, false, false, false, false, false, false])
    # Check if the element already exists in the model:
    if haskey(model.elements, ID)
        @warn "Element with ID = $(ID) already exists in the model. Overwriting it."
    end

    # Extract the information of the node (i) of the element:
    if !haskey(model.nodes, node_i_ID)
        throw(ArgumentError("Node with ID = $(node_i_ID) does not exist in the model."))
    end

    x_i, y_i, z_i = model.nodes[node_i_ID].x, model.nodes[node_i_ID].y, model.nodes[node_i_ID].z

    # Extract the information of the node (j) of the element:
    if !haskey(model.nodes, node_j_ID)
        throw(ArgumentError("Node with ID = $(node_j_ID) does not exist in the model."))
    end

    x_j, y_j, z_j = model.nodes[node_j_ID].x, model.nodes[node_j_ID].y, model.nodes[node_j_ID].z

    # Extract the information of the material of the element:
    if !haskey(model.materials, material_ID)
        throw(ArgumentError("Material with ID = $(material_ID) does not exist in the model."))
    end

    E, ν, ρ = model.materials[material_ID].E, model.materials[material_ID].ν, model.materials[material_ID].ρ

    # Extract the information of the section of the element:
    if !haskey(model.sections, section_ID)
        throw(ArgumentError("Section with ID = $(section_ID) does not exist in the model."))
    end

    A, I_zz, I_yy, J = model.sections[section_ID].A, model.sections[section_ID].I_zz, model.sections[section_ID].I_yy, model.sections[section_ID].J

    # Compute the length of the element:
    L = sqrt((x_j - x_i) ^ 2 + (y_j - y_i) ^ 2 + (z_j - z_i) ^ 2)

    # Compute the local-to-global transformation matrix of the element:
    γ, T = _compute_T(
        x_i, y_i, z_i, 
        x_j, y_j, z_j, 
        L, 
        ω)

    # Compute the element's elastic stiffness matrix in its local coordinate system:
    k_e_l = _compute_k_e_l(
        E, ν, 
        A, I_zz, I_yy, J, 
        L)

    # Compute the condensed element's elastic stiffness matrix in its local coordinate system:
    # k_e_l_c = _compute_k_e_l_c(k_e_l)

    # Compute the element's geometric stiffness matrix in its local coordinate system:
    k_g_l = _compute_k_g_l(
        A, I_zz, I_yy, 
        L)

    # Compute the condensed element's geometric stiffness matrix in its local coordinate system:
    # k_g_l_c = _compute_k_g_l_c(k_g_l)

    # Add the element to the model:
    model.elements[ID] = Element(ID, 
        node_i_ID, node_j_ID, material_ID, section_ID, 
        x_i, y_i, z_i, 
        x_j, y_j, z_j, 
        E, ν, ρ, 
        A, I_zz, I_yy, J, 
        ω, releases, 
        L, γ, T, k_e_l, k_g_l)

    # Return the updated model:
    return model
end

function add_support!(model::Model, ID::Int, u_x::Bool, u_y::Bool, u_z::Bool, θ_x::Bool, θ_y::Bool, θ_z::Bool)
    # Check if the node exists in the model:
    if !haskey(model.nodes, ID)
        throw(ArgumentError("Node with ID = $(ID) does not exist in the model."))
    end

    # Check if the support already exists in the model:
    if haskey(model.supports, ID)
        @warn "Supports at node with ID = $(ID) already exist in the model. Overwriting them."
    end

    # Add the support to the model:
    model.supports[ID] = [u_x, u_y, u_z, θ_x, θ_y, θ_z]

    # Return the updated model:
    return model
end

function add_concetrated_load!(model::Model, ID::Int, F_x::Real, F_y::Real, F_z::Real, M_x::Real, M_y::Real, M_z::Real)
    # Check if the node exists in the model:
    if !haskey(model.nodes, ID)
        throw(ArgumentError("Node with ID = $(ID) does not exist in the model."))
    end

    # Check if the concetrated load already exists in the model:
    if haskey(model.concetrated_loads, ID)
        @warn "Concetrated loads at node with ID = $(ID) already exist in the model. Overwriting them."
    end

    # Add the concetrated load to the model:
    model.concetrated_loads[ID] = [F_x, F_y, F_z, M_x, M_y, M_z]

    # Return the updated model:
    return model
end

function add_distributed_load!(model::Model, ID::Int, w_x::Real, w_y::Real, w_z::Real; CS::Symbol = :local)
    # Check if the element exists in the model:
    if !haskey(model.elements, ID)
        throw(ArgumentError("Element with ID = $(ID) does not exist in the model."))
    end

    # Check if the distributed load already exists in the model:
    if haskey(model.distributed_loads, ID)
        @warn "Distributed loads on element with ID = $(ID) already exist in the model. Overwriting them."
    end

    # Add the distributed loads to the model:
    if CS == :local # If the distributed loads are provided in the local coordinate system of the element
        # Add the distributed loads to the model:
        model.distributed_loads[ID] = [w_x, w_y, w_z]
    elseif CS == :global # If the distributed loads are provided in the global coordinate system
        # Extract the information of the element:
        x_i, y_i, z_i = model.elements[ID].x_i, model.elements[ID].y_i, model.elements[ID].z_i
        x_j, y_j, z_j = model.elements[ID].x_j, model.elements[ID].y_j, model.elements[ID].z_j
        L = model.elements[ID].L
        γ = model.elements[ID].γ

        # Compute the length of the element along each axis in the global coordinate system:
        L_x = abs(x_j - x_i)
        L_y = abs(y_j - y_i)
        L_z = abs(z_j - z_i)

        # Compute the resultants of the distributed loads:
        R_x = w_x * L_x
        R_y = w_y * L_y
        R_z = w_z * L_z
        R   = [R_x, R_y, R_z]

        # Transform the resultants to the local coordinate system of the element:
        r = γ \ R

        # Resolve the resultants in the local coordinate system of the element into distributed loads:
        w_xl, w_yl, w_zl = r / L

        # Add the distributed loads to the model:
        model.distributed_loads[ID] = [w_xl, w_yl, w_zl]
    else
        throw(ArgumentError("Coordinate system must be either `:local` or `:global`."))
    end

    # Return the updated model:
    return model
end