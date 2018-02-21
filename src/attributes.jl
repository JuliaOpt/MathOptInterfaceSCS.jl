# SCS returns one of the following integers:
# -7 SCS_INFEASIBLE_INACCURATE
# -6 SCS_UNBOUNDED_INACCURATE
# -5 SCS_SIGINT
# -4 SCS_FAILED
# -3 SCS_INDETERMINATE
# -2 SCS_INFEASIBLE  : primal infeasible, dual unbounded
# -1 SCS_UNBOUNDED   : primal unbounded, dual infeasible
#  0 SCS_UNFINISHED  : never returned, used as placeholder
#  1 SCS_SOLVED
#  2 SCS_SOLVED_INACCURATE
MOI.canget(optimizer::SCSOptimizer, ::MOI.TerminationStatus) = true
function MOI.get(optimizer::SCSOptimizer, ::MOI.TerminationStatus)
    s = optimizer.sol.ret_val
    @assert -7 <= s <= 2
    @assert s != 0
    if s in (-7, -6, 2)
        MOI.AlmostSuccess
    elseif s == -5
        MOI.Interrupted
    elseif s == -4
        MOI.NumericalError
    elseif s == -3
        MOI.SlowProgress
    else
        @assert -2 <= s <= 1
        MOI.Success
    end
end

MOI.canget(optimizer::SCSOptimizer, ::MOI.ObjectiveValue) = true
MOI.get(optimizer::SCSOptimizer, ::MOI.ObjectiveValue) = optimizer.sol.objval

MOI.canget(optimizer::SCSOptimizer, ::MOI.PrimalStatus) = true
function MOI.get(optimizer::SCSOptimizer, ::MOI.PrimalStatus)
    s = optimizer.sol.ret_val
    if s in (-3, 1, 2)
        MOI.FeasiblePoint
    elseif s in (-6, -1)
        MOI.InfeasibilityCertificate
    else
        MOI.InfeasiblePoint
    end
end
function MOI.canget(optimizer::SCSOptimizer, ::Union{MOI.VariablePrimal, MOI.ConstraintPrimal}, ::Type{<:MOI.Index})
    optimizer.sol.ret_val in (-6, -3, -1, 1, 2)
end
function MOI.get(optimizer::SCSOptimizer, ::MOI.VariablePrimal, vi::VI)
    optimizer.sol.primal[vi.value]
end
MOI.get(optimizer::SCSOptimizer, a::MOI.VariablePrimal, vi::Vector{VI}) = MOI.get.(optimizer, a, vi)
_unshift(optimizer::SCSOptimizer, offset, value, s) = value
_unshift(optimizer::SCSOptimizer, offset, value, s::Type{<:MOI.AbstractScalarSet}) = value + optimizer.cone.setconstant[offset]
reorderval(val, s) = val
function reorderval(val, ::Type{MOI.PositiveSemidefiniteConeTriangle})
    sympackedLtoU(val)
end
function MOI.get(optimizer::SCSOptimizer, ::MOI.ConstraintPrimal, ci::CI{<:MOI.AbstractFunction, S}) where S <: MOI.AbstractSet
    offset = constroffset(optimizer, ci)
    rows = constrrows(optimizer, ci)
    _unshift(optimizer, offset, scalecoef(rows, reorderval(optimizer.sol.slack[offset + rows], S), false, S), S)
end

MOI.canget(optimizer::SCSOptimizer, ::MOI.DualStatus) = true
function MOI.get(optimizer::SCSOptimizer, ::MOI.DualStatus)
    s = optimizer.sol.ret_val
    if s in (-3, 1, 2)
        MOI.FeasiblePoint
    elseif s in (-7, -2)
        MOI.InfeasibilityCertificate
    else
        MOI.InfeasiblePoint
    end
end
function MOI.canget(optimizer::SCSOptimizer, ::MOI.ConstraintDual, ::Type{<:CI})
    optimizer.sol.ret_val in (-7, -3, -2, 1, 2)
end
function MOI.get(optimizer::SCSOptimizer, ::MOI.ConstraintDual, ci::CI{<:MOI.AbstractFunction, S}) where S <: MOI.AbstractSet
    offset = constroffset(optimizer, ci)
    rows = constrrows(optimizer, ci)
    scalecoef(rows, reorderval(optimizer.sol.dual[offset + rows], S), false, S)
end

MOI.canget(optimizer::SCSOptimizer, ::MOI.ResultCount) = true
MOI.get(optimizer::SCSOptimizer, ::MOI.ResultCount) = 1
