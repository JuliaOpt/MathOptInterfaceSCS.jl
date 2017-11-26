using MathOptInterfaceSCS
using Base.Test

using MathOptInterfaceTests
const MOIT = MathOptInterfaceTests

const solver = () -> SCSInstance()
const config = MOIT.TestConfig(1e-4, 1e-4, false, false, false, false)

@testset "Continuous linear problems" begin
    MOIT.contlineartest(solver, config)
end

@testset "Continuous conic problems" begin
    MOIT.contconictest(solver, config, ["rsoc", "geomean", "rootdet", "logdet"])
end
