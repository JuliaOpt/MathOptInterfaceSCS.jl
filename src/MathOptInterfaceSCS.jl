module MathOptInterfaceSCS

export SCSInstance

using MathOptInterface
const MOI = MathOptInterface
const CR = MOI.ConstraintReference
const VR = MOI.VariableReference

using MathOptInterfaceUtilities
const MOIU = MathOptInterfaceUtilities

MOIU.@instance SCSInstanceData () (EqualTo, GreaterThan, LessThan) (Zeros, Nonnegatives, Nonpositives, SecondOrderCone, PositiveSemidefiniteConeTriangle) () (SingleVariable,) (ScalarAffineFunction,) (VectorOfVariables,) (VectorAffineFunction,)

using SCS

mutable struct SCSSolverInstance <: MOI.AbstractSolverInstance
    data::SCSInstanceData{Float64}
    varmap::Dict{VR, Int}
    constrmap::Dict{UInt64, Int}
    ret_val::Int
    primal::Vector{Float64}
    dual::Vector{Float64}
    slack::Vector{Float64}
    objval::Float64
    function SCSSolverInstance()
        new(SCSInstanceData{Float64}(), Dict{VR, Int}(), Dict{UInt64, Int}(), 1, Float64[], Float64[], Float64[], 0.)
    end
end

@bridge SplitInterval MOIU.SplitIntervalBridge () (Interval,) () () () (ScalarAffineFunction,) () ()
@bridge GeoMean MOIU.GeoMeanBridge () () (GeometricMeanCone,) () () () (VectorOfVariables,) (VectorAffineFunction,)
@bridge RootDet MOIU.RootDetBridge () () (RootDetConeTriangle,) () () () (VectorOfVariables,) (VectorAffineFunction,)

SCSInstance() = RootDet{Float64}(GeoMean{Float64}(SplitInterval{Float64}(SCSSolverInstance())))

# Redirect data modification calls to data
include("data.jl")

# Implements optimize! : translate data to SCSData and call SCS_solve
include("solve.jl")

# Implements getter for result value and statuses
include("attributes.jl")

end # module
