module MathOptInterfaceSCS

export SCSInstance

using MathOptInterface
const MOI = MathOptInterface
const CR = MOI.ConstraintReference

using MathOptInterfaceUtilities
const MOIU = MathOptInterfaceUtilities

MOIU.@instance SCSInstanceData () (EqualTo, GreaterThan, LessThan) (Zeros, Nonnegatives, Nonpositives, SecondOrderCone, PositiveSemidefiniteConeTriangle) () (SingleVariable,) (ScalarAffineFunction,) (VectorOfVariables,) (VectorAffineFunction,)

struct SCSSolverInstance <: MOI.AbstractSolverInstance
    data::SCSInstanceData{Float64}
    function SCSSolverInstance()
        new(SCSInstanceData{Float64}())
    end
end

@bridge SplitInterval MOIU.SplitIntervalBridge () (Interval,) () () () (ScalarAffineFunction,) () ()
@bridge GeoMean MOIU.GeoMeanBridge () () (GeometricMeanCone,) () () () (VectorOfVariables,) (VectorAffineFunction,)
@bridge RootDet MOIU.RootDetBridge () () (RootDetConeTriangle,) () () () (VectorOfVariables,) (VectorAffineFunction,)

SCSInstance() = RootDet{Float64}(GeoMean{Float64}(SplitInterval{Float64}(SCSSolverInstance())))

# Redirect data modification calls to data
include("data.jl")

end # module
