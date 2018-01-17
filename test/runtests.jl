using MathOptInterfaceSCS
using Base.Test

using MathOptInterfaceTests
const MOIT = MathOptInterfaceTests

const solver = () -> SCSInstance()
# linear9test needs 1e-3 with SCS < 2.0 and 5e-1 with SCS 2.0
# linear2test needs 1e-4
const config = MOIT.TestConfig(1e-4, 1e-4, true, true, true, true)

@testset "Continuous linear problems" begin
    # AlmostSuccess for linear9 with SCS 2
    MOIT.contlineartest(solver, config, ["linear9"])
end

@testset "Continuous conic problems" begin
    MOIT.contconictest(solver, config, ["rsoc", "geomean", "rootdet"])
end
