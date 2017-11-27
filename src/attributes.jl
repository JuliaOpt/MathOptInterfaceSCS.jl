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
    s = instance.ret_val
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
MOI.get(instance::SCSSolverInstance, ::MOI.ObjectiveValue) = instance.objval

MOI.canget(instance::SCSSolverInstance, ::MOI.PrimalStatus) = true
function MOI.get(instance::SCSSolverInstance, ::MOI.PrimalStatus)
    s = instance.ret_val
    if s in (-3, 1, 2)
        MOI.FeasiblePoint
    elseif s in (-6, -1)
        MOI.InfeasibilityCertificate
    else
        MOI.InfeasiblePoint
    end
end
function MOI.canget(instance::SCSSolverInstance, ::Union{MOI.VariablePrimal, MOI.ConstraintPrimal}, r::MOI.AnyReference)
    instance.ret_val in (-6, -3, -1, 1, 2)
end
function MOI.canget(instance::SCSSolverInstance, ::Union{MOI.VariablePrimal, MOI.ConstraintPrimal}, r::Vector{<:MOI.AnyReference})
    instance.ret_val in (-6, -3, -1, 1, 2)
end
function MOI.get(instance::SCSSolverInstance, ::MOI.VariablePrimal, vr::VR)
    instance.primal[instance.varmap[vr]]
end
MOI.get(instance::SCSSolverInstance, a::MOI.VariablePrimal, vr::Vector{VR}) = MOI.get.(instance, a, vr)
_unshift(value, s) = value
_unshift(value, s::MOI.EqualTo) = value + s.value
_unshift(value, s::MOI.GreaterThan) = value + s.lower
_unshift(value, s::MOI.LessThan) = value + s.upper
function MOI.get(instance::SCSSolverInstance, ::MOI.ConstraintPrimal, cr::CR)
    offset = instance.constrmap[cr.value]
    s = MOI.get(instance, MOI.ConstraintSet(), cr)
    rows = constrrows(s)
    _unshift(scalecoef(rows, instance.slack[offset + rows], false, s), s)
end

MOI.canget(instance::SCSSolverInstance, ::MOI.DualStatus) = true
function MOI.get(instance::SCSSolverInstance, ::MOI.DualStatus)
    s = instance.ret_val
    if s in (-3, 1, 2)
        MOI.FeasiblePoint
    elseif s in (-7, -2)
        MOI.InfeasibilityCertificate
    else
        MOI.InfeasiblePoint
    end
end
function MOI.canget(instance::SCSSolverInstance, ::MOI.ConstraintDual, ::CR)
    instance.ret_val in (-7, -3, -2, 1, 2)
end
function MOI.get(instance::SCSSolverInstance, ::MOI.ConstraintDual, cr::CR)
    offset = instance.constrmap[cr.value]
    s = MOI.get(instance, MOI.ConstraintSet(), cr)
    rows = constrrows(s)
    scalecoef(rows, instance.dual[offset + rows], false, s)
end

MOI.canget(instance::SCSSolverInstance, ::MOI.ResultCount) = true
MOI.get(instance::SCSSolverInstance, ::MOI.ResultCount) = 1
