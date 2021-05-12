module AndorInstaller

include("tools.jl")
target = "deps.jl"
rm(target; force=true)
AndorInstallTools.make_deps(target)

end # module
