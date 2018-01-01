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
MOI.canget(instance::SCSSolverInstance, ::MOI.TerminationStatus) = true
function MOI.get(instance::SCSSolverInstance, ::MOI.TerminationStatus)
    s = instance.sol.ret_val
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

MOI.canget(instance::SCSSolverInstance, ::MOI.ObjectiveValue) = true
MOI.get(instance::SCSSolverInstance, ::MOI.ObjectiveValue) = instance.sol.objval

MOI.canget(instance::SCSSolverInstance, ::MOI.PrimalStatus) = true
function MOI.get(instance::SCSSolverInstance, ::MOI.PrimalStatus)
    s = instance.sol.ret_val
    if s in (-3, 1, 2)
        MOI.FeasiblePoint
    elseif s in (-6, -1)
        MOI.InfeasibilityCertificate
    else
        MOI.InfeasiblePoint
    end
end
function MOI.canget(instance::SCSSolverInstance, ::Union{MOI.VariablePrimal, MOI.ConstraintPrimal}, r::MOI.Index)
    instance.sol.ret_val in (-6, -3, -1, 1, 2)
end
function MOI.canget(instance::SCSSolverInstance, ::Union{MOI.VariablePrimal, MOI.ConstraintPrimal}, r::Vector{<:MOI.Index})
    instance.sol.ret_val in (-6, -3, -1, 1, 2)
end
function MOI.get(instance::SCSSolverInstance, ::MOI.VariablePrimal, vi::VI)
    vi = instance.idxmap[vi]
    instance.sol.primal[vi.value]
end
MOI.get(instance::SCSSolverInstance, a::MOI.VariablePrimal, vi::Vector{VI}) = MOI.get.(instance, a, vi)
_unshift(instance::SCSSolverInstance, offset, value, s) = value
_unshift(instance::SCSSolverInstance, offset, value, s::Type{<:MOI.AbstractScalarSet}) = value + instance.cone.setconstant[offset]
reorderval(val, s) = val
function reorderval(val, ::Type{MOI.PositiveSemidefiniteConeTriangle})
    sympackedLtoU(val)
end
function MOI.get(instance::SCSSolverInstance, ::MOI.ConstraintPrimal, ci::CI{<:MOI.AbstractFunction, S}) where S <: MOI.AbstractSet
    ci = instance.idxmap[ci]
    offset = constroffset(instance, ci)
    rows = constrrows(instance, ci)
    _unshift(instance, offset, scalecoef(rows, reorderval(instance.sol.slack[offset + rows], S), false, S), S)
end

MOI.canget(instance::SCSSolverInstance, ::MOI.DualStatus) = true
function MOI.get(instance::SCSSolverInstance, ::MOI.DualStatus)
    s = instance.sol.ret_val
    if s in (-3, 1, 2)
        MOI.FeasiblePoint
    elseif s in (-7, -2)
        MOI.InfeasibilityCertificate
    else
        MOI.InfeasiblePoint
    end
end
function MOI.canget(instance::SCSSolverInstance, ::MOI.ConstraintDual, ::CI)
    instance.sol.ret_val in (-7, -3, -2, 1, 2)
end
function MOI.get(instance::SCSSolverInstance, ::MOI.ConstraintDual, ci::CI{<:MOI.AbstractFunction, S}) where S <: MOI.AbstractSet
    ci = instance.idxmap[ci]
    offset = constroffset(instance, ci)
    rows = constrrows(instance, ci)
    scalecoef(rows, reorderval(instance.sol.dual[offset + rows], S), false, S)
end

MOI.canget(instance::SCSSolverInstance, ::MOI.ResultCount) = true
MOI.get(instance::SCSSolverInstance, ::MOI.ResultCount) = 1
