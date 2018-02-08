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

using SCS

include("types.jl")

mutable struct SCSInstance <: MOI.AbstractSolverInstance
    cone::Cone
    maxsense::Bool
    data::Union{Void, Data} # only non-Void between MOI.copy! and MOI.optimize!
    sol::Solution
    function SCSInstance()
        new(Cone(), false, nothing, Solution())
    end
end

function MOI.empty!(instance::SCSInstance)
    instance.maxsense = false
    instance.data = nothing # It should already be nothing except if an error is thrown inside copy!
end

MOI.canaddvariable(instance::SCSInstance) = false

MOI.copy!(dest::SCSInstance, src::MOI.AbstractInstance) = MOIU.allocateload!(dest, src)

# Implements optimize! : translate data to SCSData and call SCS_solve
include("solve.jl")

# Implements getter for result value and statuses
include("attributes.jl")

end # module
