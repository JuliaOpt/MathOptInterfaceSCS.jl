using MathOptInterfaceSCS
using Base.Test

using MathOptInterfaceTests
const MOIT = MathOptInterfaceTests

const solver = () -> SCSInstance()
# linear9test needs 1e-3
const config = MOIT.TestConfig(1e-3, 1e-3, true, true, true, true)

@testset "Continuous linear problems" begin
    MOIT.contlineartest(solver, config)
end

@testset "Continuous conic problems" begin
    MOIT.contconictest(solver, config, ["soc3", "rsoc", "geomean", "rootdet", "logdet"])
end
