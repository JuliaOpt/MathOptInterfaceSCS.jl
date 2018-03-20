module MathOptInterfaceSCS

export SCSOptimizer

using MathOptInterface
const MOI = MathOptInterface
const CI = MOI.ConstraintIndex
const VI = MOI.VariableIndex

const MOIU = MOI.Utilities

const SF = Union{MOI.SingleVariable, MOI.ScalarAffineFunction{Float64}, MOI.VectorOfVariables, MOI.VectorAffineFunction{Float64}}
const SS = Union{MOI.EqualTo{Float64}, MOI.GreaterThan{Float64}, MOI.LessThan{Float64}, MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives, MOI.SecondOrderCone, MOI.ExponentialCone, MOI.PositiveSemidefiniteConeTriangle}

using SCS

include("types.jl")

mutable struct SCSOptimizer <: MOI.AbstractOptimizer
    cone::Cone
    maxsense::Bool
    data::Union{Void, Data} # only non-Void between MOI.copy! and MOI.optimize!
    sol::Solution
    function SCSOptimizer()
        new(Cone(), false, nothing, Solution())
    end
end

function MOI.isempty(optimizer::SCSOptimizer)
    !optimizer.maxsense && optimizer.data === nothing
end
function MOI.empty!(optimizer::SCSOptimizer)
    optimizer.maxsense = false
    optimizer.data = nothing # It should already be nothing except if an error is thrown inside copy!
end

MOI.canaddvariable(optimizer::SCSOptimizer) = false

MOI.supports(::SCSOptimizer, ::MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}) = true
MOI.supportsconstraint(::SCSOptimizer, ::Type{<:SF}, ::Type{<:SS}) = true
MOI.copy!(dest::SCSOptimizer, src::MOI.ModelLike) = MOIU.allocateload!(dest, src)

# Implements optimize! : translate data to SCSData and call SCS_solve
include("solve.jl")

# Implements getter for result value and statuses
include("attributes.jl")

end # module
