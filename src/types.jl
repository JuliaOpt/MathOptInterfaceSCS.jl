struct Solution
    ret_val::Int
    primal::Vector{Float64}
    dual::Vector{Float64}
    slack::Vector{Float64}
    objval::Float64
end
Solution() = Solution(0, # SCS_UNFINISHED
                      Float64[], Float64[], Float64[], NaN)

mutable struct Data
    m::Int
    n::Int
    I::Vector{Int}
    J::Vector{Int}
    V::Vector{Float64}
    b::Vector{Float64}
    objconstant::Float64
    c::Vector{Float64}
end

mutable struct Cone
    f::Int # number of linear equality constraints
    l::Int # length of LP cone
    q::Int # length of SOC cone
    qa::Vector{Int} # array of second-order cone constraints
    s::Int # length of SD cone
    sa::Vector{Int} # array of semi-definite constraints
    ep::Int # number of primal exponential cone triples
    ed::Int # number of dual exponential cone triples
    p::Vector{Float64} # array of power cone params
    setconstant::Dict{Int, Float64} # For the constant of EqualTo, LessThan and GreaterThan
    nrows::Dict{Int, Int} # The number of rows of each vector sets
    function Cone()
        new(0, 0,
            0, Int[],
            0, Int[],
            0, 0, Float64[],
            Dict{Int, Float64}(),
            Dict{Int, UnitRange{Int}}())
    end
end
