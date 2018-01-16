# References
MOI.candelete(instance::SCSSolverInstance, r::MOI.Index) = MOI.candelete(instance.instancedata, r)
MOI.isvalid(instance::SCSSolverInstance, r::MOI.Index) = MOI.isvalid(instance.instancedata, r)
MOI.delete!(instance::SCSSolverInstance, r::MOI.Index) = MOI.delete!(instance.instancedata, r)

# Attributes
for f in (:canget, :canset, :set!, :get, :get!)
    @eval begin
        MOI.$f(instance::SCSSolverInstance, attr::MOI.AnyAttribute) = MOI.$f(instance.instancedata, attr)
        # Objective function
        MOI.$f(instance::SCSSolverInstance, attr::MOI.AnyAttribute, arg::Union{MOI.OptimizationSense, MOI.AbstractScalarFunction}) = MOI.$f(instance.instancedata, attr, arg)
    end
end
for f in (:canget, :canset)
    @eval begin
        MOI.$f(instance::SCSSolverInstance, attr::MOI.AnyAttribute, index::Type{<:MOI.Index}) = MOI.$f(instance.instancedata, attr, index)
    end
end
for f in (:set!, :get, :get!)
    @eval begin
        MOI.$f(instance::SCSSolverInstance, attr::MOI.AnyAttribute, index::MOI.Index) = MOI.$f(instance.instancedata, attr, index)
        MOI.$f(instance::SCSSolverInstance, attr::MOI.AnyAttribute, indices::Vector{<:MOI.Index}) = MOI.$f(instance.instancedata, attr, indices)
    end
end

# Constraints
MOI.canaddconstraint(instance::SCSSolverInstance, f::MOI.AbstractFunction, s::MOI.AbstractSet) = MOI.canaddconstraint(instance.instancedata, f, s)
MOI.addconstraint!(instance::SCSSolverInstance, f::MOI.AbstractFunction, s::MOI.AbstractSet) = MOI.addconstraint!(instance.instancedata, f, s)
MOI.canmodifyconstraint(instance::SCSSolverInstance, ci::CI, change) = MOI.canmodifyconstraint(instance.instancedata, ci, change)
MOI.modifyconstraint!(instance::SCSSolverInstance, ci::CI, change) = MOI.modifyconstraint!(instance.instancedata, ci, change)

# Objective
MOI.canmodifyobjective(instance::SCSSolverInstance, change::MOI.AbstractFunctionModification) = MOI.canmodifyobjective(instance.instancedata, change)
MOI.modifyobjective!(instance::SCSSolverInstance, change::MOI.AbstractFunctionModification) = MOI.modifyobjective!(instance.instancedata, change)

# Variables
MOI.addvariable!(instance::SCSSolverInstance) = MOI.addvariable!(instance.instancedata)
MOI.addvariables!(instance::SCSSolverInstance, n) = MOI.addvariables!(instance.instancedata, n)
