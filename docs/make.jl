push!(LOAD_PATH, "../src/")

using Hephaestus
using Documenter
using DocumenterCitations

makedocs(
    sitename = "Hephaestus.jl",
    authors = "Damir Akchurin, AkchurinDA@gmail.com",
    pages = [
        "Home"                   => "index.md",
        "Quick Start"            => "QuickStart.md",
        "Theoretical Background" => [
            "Bisymmetric Framework Element Formulation" => "BisymmetricFrameworkElementFormulation.md",
            "Coordinate Transformation"                 => "CoordinateTransformation.md",
            "Analyses Types"                            => "AnalysesTypes.md"
        ],
        "API"                    => "API.md"],
    format = Documenter.HTML(
            assets = [
                "assets/favicon.ico",
                "assets/Citations.css",
                "assets/Custom.css"]),
    plugins = [
        CitationBibliography(
            joinpath(@__DIR__, "src", "References.bib"),
            style = :numeric)])

deploydocs(
    repo = "github.com/AkchurinDA/Hephaestus.jl")