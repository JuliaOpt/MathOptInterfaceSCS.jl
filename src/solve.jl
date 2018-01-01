const ZeroCones = Union{MOI.EqualTo, MOI.Zeros}
const LPCones = Union{MOI.GreaterThan, MOI.LessThan, MOI.Nonnegatives, MOI.Nonpositives}

_dim(s::MOI.AbstractScalarSet) = 1
_dim(s::MOI.AbstractVectorSet) = MOI.dimension(s)

# Computes cone dimensions
constroffset(cone::Cone, ci::CI{<:MOI.AbstractFunction, <:ZeroCones}) = ci.value
function _allocateconstraint!(cone::Cone, f, s::ZeroCones)
    ci = cone.f
    cone.f += _dim(s)
    ci
end
constroffset(cone::Cone, ci::CI{<:MOI.AbstractFunction, <:LPCones}) = cone.f + ci.value
function _allocateconstraint!(cone::Cone, f, s::LPCones)
    ci = cone.l
    cone.l += _dim(s)
    ci
end
constroffset(cone::Cone, ci::CI{<:MOI.AbstractFunction, <:MOI.SecondOrderCone}) = cone.f + cone.l + ci.value
function _allocateconstraint!(cone::Cone, f, s::MOI.SecondOrderCone)
    push!(cone.qa, s.dimension)
    ci = cone.q
    cone.q += _dim(s)
    ci
end
constroffset(cone::Cone, ci::CI{<:MOI.AbstractFunction, <:MOI.PositiveSemidefiniteConeTriangle}) = cone.f + cone.l + cone.q + ci.value
function _allocateconstraint!(cone::Cone, f, s::MOI.PositiveSemidefiniteConeTriangle)
    push!(cone.sa, s.dimension)
    ci = cone.s
    cone.s += _dim(s)
    ci
end
constroffset(cone::Cone, ci::CI{<:MOI.AbstractFunction, <:MOI.ExponentialCone}) = cone.f + cone.l + cone.q + cone.s + ci.value
function _allocateconstraint!(cone::Cone, f, s::MOI.ExponentialCone)
    ci = 3cone.ep
    cone.ep += 1
    ci
end
constroffset(instance::SCSSolverInstance, ci) = constroffset(instance.cone, ci)
function MOIU.allocateconstraint!(instance::SCSSolverInstance, f::F, s::S) where {F <: MOI.AbstractFunction, S <: MOI.AbstractSet}
    CI{F, S}(_allocateconstraint!(instance.cone, f, s))
end

# Vectorized length for matrix dimension n
sympackedlen(n) = (n*(n+1)) >> 1
# Matrix dimension for vectorized length n
sympackeddim(n) = div(isqrt(1+8n) - 1, 2)
trimap(i::Integer, j::Integer) = i < j ? trimap(j, i) : div((i-1)*i, 2) + j
trimapL(i::Integer, j::Integer, n::Integer) = i < j ? trimapL(j, i, n) : i + div((2n-j) * (j-1), 2)
function _sympackedto(x, n, mapfrom, mapto)
    @assert length(x) == sympackedlen(n)
    y = similar(x)
    for i in 1:n, j in 1:i
        y[mapto(i, j)] = x[mapfrom(i, j)]
    end
    y
end
sympackedLtoU(x, n=sympackeddim(length(x))) = _sympackedto(x, n, (i, j) -> trimapL(i, j, n), trimap)
sympackedUtoL(x, n=sympackeddim(length(x))) = _sympackedto(x, n, trimap, (i, j) -> trimapL(i, j, n))

function sympackedUtoLidx(x::AbstractVector{<:Integer}, n)
    y = similar(x)
    map = sympackedLtoU(1:sympackedlen(n), n)
    for i in eachindex(y)
        y[i] = map[x[i]]
    end
    y
end


# Build constraint matrix
scalecoef(rows, coef, minus, s) = minus ? -coef : coef
scalecoef(rows, coef, minus, s::Union{MOI.LessThan, Type{<:MOI.LessThan}, MOI.Nonpositives, Type{MOI.Nonpositives}}) = minus ? coef : -coef
function _scalecoef(rows, coef, minus, d, rev)
    scaling = minus ? -1 : 1
    scaling2 = rev ? scaling / sqrt(2) : scaling * sqrt(2)
    output = copy(coef)
    diagidx = IntSet()
    for i in 1:d
        push!(diagidx, trimap(i, i))
    end
    for i in 1:length(output)
        if rows[i] in diagidx
            output[i] *= scaling
        else
            output[i] *= scaling2
        end
    end
    output
end
function scalecoef(rows, coef, minus, s::MOI.PositiveSemidefiniteConeTriangle)
    _scalecoef(rows, coef, minus, s.dimension, false)
end
function scalecoef(rows, coef, minus, ::Type{MOI.PositiveSemidefiniteConeTriangle})
    _scalecoef(rows, coef, minus, sympackeddim(length(rows)), true)
end
_varmap(f) = map(vi -> vi.value, f.variables)
_constant(s::MOI.EqualTo) = s.value
_constant(s::MOI.GreaterThan) = s.lower
_constant(s::MOI.LessThan) = s.upper
constrrows(::MOI.AbstractScalarSet) = 1
constrrows(s::MOI.AbstractVectorSet) = 1:MOI.dimension(s)
constrrows(instance::SCSSolverInstance, ci::CI{<:MOI.AbstractScalarFunction, <:MOI.AbstractScalarSet}) = 1
constrrows(instance::SCSSolverInstance, ci::CI{<:MOI.AbstractVectorFunction, <:MOI.AbstractVectorSet}) = 1:instance.cone.nrows[constroffset(instance, ci)]
MOIU.loadconstraint!(instance::SCSSolverInstance, ci, f::MOI.SingleVariable, s) = MOIU.loadconstraint!(instance, ci, MOI.ScalarAffineFunction{Float64}(f), s)
function MOIU.loadconstraint!(instance::SCSSolverInstance, ci, f::MOI.ScalarAffineFunction, s)
    a = sparsevec(_varmap(f), f.coefficients)
    # sparsevec combines duplicates with + but does not remove zeros created so we call dropzeros!
    dropzeros!(a)
    offset = constroffset(instance, ci)
    row = constrrows(s)
    i = offset + row
    # The SCS format is b - Ax ∈ cone
    # so minus=false for b and minus=true for A
    setconstant = _constant(s)
    instance.cone.setconstant[offset] = setconstant
    constant = f.constant - setconstant
    instance.data.b[i] = scalecoef(row, constant, false, s)
    append!(instance.data.I, fill(i, length(a.nzind)))
    append!(instance.data.J, a.nzind)
    append!(instance.data.V, scalecoef(row, a.nzval, true, s))
end
MOIU.loadconstraint!(instance::SCSSolverInstance, ci, f::MOI.VectorOfVariables, s) = MOIU.loadconstraint!(instance, ci, MOI.VectorAffineFunction{Float64}(f), s)
orderval(val, s) = val
function orderval(val, s::MOI.PositiveSemidefiniteConeTriangle)
    sympackedUtoL(val, s.dimension)
end
orderidx(idx, s) = idx
function orderidx(idx, s::MOI.PositiveSemidefiniteConeTriangle)
    sympackedUtoLidx(idx, s.dimension)
end
function MOIU.loadconstraint!(instance::SCSSolverInstance, ci, f::MOI.VectorAffineFunction, s)
    A = sparse(f.outputindex, _varmap(f), f.coefficients)
    # sparse combines duplicates with + but does not remove zeros created so we call dropzeros!
    dropzeros!(A)
    colval = zeros(Int, length(A.rowval))
    for col in 1:A.n
        colval[A.colptr[col]:(A.colptr[col+1]-1)] = col
    end
    @assert !any(iszero.(colval))
    offset = constroffset(instance, ci)
    rows = constrrows(s)
    instance.cone.nrows[offset] = length(rows)
    i = offset + rows
    # The SCS format is b - Ax ∈ cone
    # so minus=false for b and minus=true for A
    instance.data.b[i] = scalecoef(rows, orderval(f.constant, s), false, s)
    append!(instance.data.I, offset + orderidx(A.rowval, s))
    append!(instance.data.J, colval)
    append!(instance.data.V, scalecoef(A.rowval, A.nzval, true, s))
end

function constrcall(arg::Tuple, constrs::Vector)
    for constr in constrs
        constrcall(arg..., constr...)
    end
end

function MOIU.allocatevariables!(instance::SCSSolverInstance, nvars::Integer)
    instance.cone = Cone()
    VI.(1:nvars)
end

function MOIU.loadvariables!(instance::SCSSolverInstance, nvars::Integer)
    cone = instance.cone
    m = cone.f + cone.l + cone.q + cone.s + 3cone.ep + cone.ed
    I = Int[]
    J = Int[]
    V = Float64[]
    b = zeros(m)
    c = zeros(nvars)
    instance.data = Data(m, nvars, I, J, V, b, 0., false, c)
end

function MOIU.allocateobjective!(instance::SCSSolverInstance, sense::MOI.OptimizationSense, f::MOI.ScalarAffineFunction) end

function MOIU.loadobjective!(instance::SCSSolverInstance, sense::MOI.OptimizationSense, f::MOI.ScalarAffineFunction)
    c0 = full(sparsevec(_varmap(f), f.coefficients, instance.data.n))
    instance.data.objconstant = f.constant
    instance.data.maxsense = sense == MOI.MaxSense
    instance.data.c = instance.data.maxsense ? -c0 : c0
end

function MOI.optimize!(instance::SCSSolverInstance)
    instance.idxmap = MOI.copy!(instance, instance.instancedata)
    cone = instance.cone
    m = instance.data.m
    n = instance.data.n
    A = sparse(instance.data.I, instance.data.J, instance.data.V)
    b = instance.data.b
    objconstant = instance.data.objconstant
    maxsense = instance.data.maxsense
    c = instance.data.c
    instance.data = nothing # Allows GC to free instance.data before A is loaded to SCS
    sol = SCS_solve(SCS.Indirect, m, n, A, b, c, cone.f, cone.l, cone.qa, cone.sa, cone.ep, cone.ed, cone.p)
    ret_val = sol.ret_val
    primal = sol.x
    dual = sol.y
    slack = sol.s
    objval = (maxsense ? -1 : 1) * dot(c, primal) + objconstant
    instance.sol = Solution(ret_val, primal, dual, slack, objval)
end
