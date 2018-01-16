module MathOptInterfaceSCS

export SCSInstance

using MathOptInterface
const MOI = MathOptInterface
const CI = MOI.ConstraintIndex
const VI = MOI.VariableIndex

using MathOptInterfaceUtilities
const MOIU = MathOptInterfaceUtilities

const SF = Union{MOI.SingleVariable, MOI.ScalarAffineFunction{Float64}, MOI.VectorOfVariables, MOI.VectorAffineFunction{Float64}}
const SS = Union{MOI.EqualTo{Float64}, MOI.GreaterThan{Float64}, MOI.LessThan{Float64}, MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives, MOI.SecondOrderCone, MOI.ExponentialCone, MOI.PositiveSemidefiniteConeTriangle}


MOIU.@instance SCSInstanceData () (EqualTo, GreaterThan, LessThan) (Zeros, Nonnegatives, Nonpositives, SecondOrderCone, ExponentialCone, PositiveSemidefiniteConeTriangle) () (SingleVariable,) (ScalarAffineFunction,) (VectorOfVariables,) (VectorAffineFunction,)

using SCS

include("types.jl")

mutable struct SCSSolverInstance <: MOI.AbstractSolverInstance
    instancedata::SCSInstanceData{Float64} # Will be removed when
    idxmap::MOIU.IndexMap                  # InstanceManager is ready
    cone::Cone
    maxsense::Bool
    data::Union{Void, Data} # only non-Void between MOI.copy! and MOI.optimize!
    sol::Solution
    function SCSSolverInstance()
        new(SCSInstanceData{Float64}(), MOIU.IndexMap(), Cone(), false, nothing, Solution())
    end
end

function MOI.empty!(instance::SCSSolverInstance) end

@bridge SplitInterval MOIU.SplitIntervalBridge () (Interval,) () () () (ScalarAffineFunction,) () ()
@bridge GeoMean MOIU.GeoMeanBridge () () (GeometricMeanCone,) () () () (VectorOfVariables,) (VectorAffineFunction,)
@bridge LogDet MOIU.LogDetBridge () () (LogDetConeTriangle,) () () () (VectorOfVariables,) (VectorAffineFunction,)
@bridge RootDet MOIU.RootDetBridge () () (RootDetConeTriangle,) () () () (VectorOfVariables,) (VectorAffineFunction,)

SCSInstance() = RootDet{Float64}(LogDet{Float64}(GeoMean{Float64}(SplitInterval{Float64}(SCSSolverInstance()))))

MOI.copy!(dest::SCSSolverInstance, src::MOI.AbstractInstance) = MOIU.allocateload!(dest, src)

# Redirect data modification calls to data
include("data.jl")

# Implements optimize! : translate data to SCSData and call SCS_solve
include("solve.jl")

# Implements getter for result value and statuses
include("attributes.jl")

end # module
