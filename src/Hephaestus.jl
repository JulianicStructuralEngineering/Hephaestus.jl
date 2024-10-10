module Hephaestus
using BlockDiagonals
using OrderedCollections
using StyledStrings
using LinearAlgebra

using DocStringExtensions

abstract type AbstractAnalysisType end
abstract type AbstractSolutionCache end

include("Model.jl")
export Node, Material, Section, Element, Model
include("ModelUtilities.jl")
export add_node!, add_material!, add_section!, add_element!, add_support!, add_conc_load!, add_dist_load!
export del_node!, del_material!, del_section!, del_element!, del_support!, del_conc_load!, del_dist_load!
export get_node_u_g, get_element_u_l, get_element_f_l
include("Analysis.jl")
export O1EAnalysis, O1ESolutionCache # 1st-order elastic analysis
export O2EAnalysis, O2ESolutionCache # 2nd-order elastic analysis
export EBAnalysis, EBSolutionCache   # Elastic buckling analysis
export FVAnalysis, FVSolutionCache   # Free vibration analysis
export solve
include("AnalysisUtilities.jl")
include("Plotting.jl")
export plotmodel, plotmodel!
export plotsolution, plotsolution!
end