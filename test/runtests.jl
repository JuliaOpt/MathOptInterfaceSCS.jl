using MathOptInterfaceSCS
using Base.Test

using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities

using MathOptInterfaceBridges
const MOIB = MathOptInterfaceBridges

MOIU.@model SCSModelData () (EqualTo, GreaterThan, LessThan) (Zeros, Nonnegatives, Nonpositives, SecondOrderCone, ExponentialCone, PositiveSemidefiniteConeTriangle) () (SingleVariable,) (ScalarAffineFunction,) (VectorOfVariables,) (VectorAffineFunction,)

MOIB.@bridge SplitInterval MOIB.SplitIntervalBridge () (Interval,) () () () (ScalarAffineFunction,) () ()
MOIB.@bridge LogDet MOIB.LogDetBridge () () (LogDetConeTriangle,) () () () (VectorOfVariables,) (VectorAffineFunction,)
MOIB.@bridge RootDet MOIB.RootDetBridge () () (RootDetConeTriangle,) () () () (VectorOfVariables,) (VectorAffineFunction,)

# linear9test needs 1e-3 with SCS < 2.0 and 5e-1 with SCS 2.0
# linear2test needs 1e-4
const config = MOIT.TestConfig(atol=1e-4, rtol=1e-4)

@testset "Continuous linear problems" begin
    # AlmostSuccess for linear9 with SCS 2
    MOIT.contlineartest(SplitInterval{Float64}(MOIU.CachingOptimizer(SCSModelData{Float64}(), SCSOptimizer())), config, ["linear9"])
end

@testset "Continuous conic problems" begin
    MOIT.contconictest(RootDet{Float64}(LogDet{Float64}(MOIU.CachingOptimizer(SCSModelData{Float64}(), SCSOptimizer()))), config, ["rsoc", "geomean", "rootdet"])
end
