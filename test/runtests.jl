using MathOptInterfaceSCS
using Base.Test

using MathOptInterfaceTests
const MOIT = MathOptInterfaceTests

using MathOptInterfaceUtilities
const MOIU = MathOptInterfaceUtilities

MOIU.@instance SCSInstanceData () (EqualTo, GreaterThan, LessThan) (Zeros, Nonnegatives, Nonpositives, SecondOrderCone, ExponentialCone, PositiveSemidefiniteConeTriangle) () (SingleVariable,) (ScalarAffineFunction,) (VectorOfVariables,) (VectorAffineFunction,)

MOIU.@bridge SplitInterval MOIU.SplitIntervalBridge () (Interval,) () () () (ScalarAffineFunction,) () ()
MOIU.@bridge LogDet MOIU.LogDetBridge () () (LogDetConeTriangle,) () () () (VectorOfVariables,) (VectorAffineFunction,)
MOIU.@bridge RootDet MOIU.RootDetBridge () () (RootDetConeTriangle,) () () () (VectorOfVariables,) (VectorAffineFunction,)

# linear9test needs 1e-3 with SCS < 2.0 and 5e-1 with SCS 2.0
# linear2test needs 1e-4
const config = MOIT.TestConfig(atol=1e-4, rtol=1e-4)

@testset "Continuous linear problems" begin
    # AlmostSuccess for linear9 with SCS 2
    MOIT.contlineartest(SplitInterval{Float64}(MOIU.InstanceManager(SCSInstanceData{Float64}(), SCSInstance())), config, ["linear9"])
end

@testset "Continuous conic problems" begin
    MOIT.contconictest(RootDet{Float64}(LogDet{Float64}(MOIU.InstanceManager(SCSInstanceData{Float64}(), SCSInstance()))), config, ["rsoc", "geomean", "rootdet"])
end
