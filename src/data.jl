# References
MOI.candelete(instance::SCSSolverInstance, r::MOI.AnyReference) = MOI.candelete(instance.data, r)
MOI.isvalid(instance::SCSSolverInstance, r::MOI.AnyReference) = MOI.isvalid(instance.data, r)
MOI.delete!(instance::SCSSolverInstance, r::MOI.AnyReference) = MOI.delete!(instance.data, r)

# Attributes
for f in (:canget, :canset, :set!, :get, :get!)
    @eval begin
        MOI.$f(instance::SCSSolverInstance, attr::MOI.AnyAttribute) = MOI.$f(instance.data, attr)
        MOI.$f(instance::SCSSolverInstance, attr::MOI.AnyAttribute, ref::MOI.AnyReference) = MOI.$f(instance.data, attr, ref)
        MOI.$f(instance::SCSSolverInstance, attr::MOI.AnyAttribute, refs::Vector{<:MOI.AnyReference}) = MOI.$f(instance.data, attr, refs)
        # Objective function
        MOI.$f(instance::SCSSolverInstance, attr::MOI.AnyAttribute, arg::Union{MOI.OptimizationSense, MOI.AbstractScalarFunction}) = MOI.$f(instance.data, attr, arg)
    end
end

# Constraints
MOI.canaddconstraint(instance::SCSSolverInstance, f::MOI.AbstractFunction, s::MOI.AbstractSet) = MOI.canaddconstraint(instance.data, f, s)
MOI.addconstraint!(instance::SCSSolverInstance, f::MOI.AbstractFunction, s::MOI.AbstractSet) = MOI.addconstraint!(instance.data, f, s)
MOI.canmodifyconstraint(instance::SCSSolverInstance, cr::CR, change) = MOI.canmodifyconstraint(instance.data, cr, change)
MOI.modifyconstraint!(instance::SCSSolverInstance, cr::CR, change) = MOI.modifyconstraint!(instance.data, cr, change)

# Objective
MOI.canmodifyobjective(instance::SCSSolverInstance, change::MOI.AbstractFunctionModification) = MOI.canmodifyobjective(instance.data, change)
MOI.modifyobjective!(instance::SCSSolverInstance, change::MOI.AbstractFunctionModification) = MOI.modifyobjective!(instance.data, change)

# Variables
MOI.addvariable!(instance::SCSSolverInstance) = MOI.addvariable!(instance.data)
MOI.addvariables!(instance::SCSSolverInstance, n) = MOI.addvariables!(instance.data, n)
