# quire.jl -- exact fused dot product (quire) accumulator for Posit types.
#
# The quire is Universal's exact accumulator: products of posits are summed with
# NO intermediate rounding, and a single rounding occurs on conversion back to a
# Posit.  This is posit-only (the quire is a posit construct in Universal) and is
# entirely opt-in -- ordinary Posit arithmetic and existing dot products are
# unchanged.  Use it when you want an exact fused dot product:
#
#     a = rand(Posit{32,2}, 1000); b = rand(Posit{32,2}, 1000)
#     r = fdp(a, b)                      # exact, rounds once
#
# or accumulate by hand (mirrors the C++ `q += quire_mul(pa,pb)` idiom):
#
#     q = Quire(Posit{32,2})
#     for i in eachindex(a, b); fma_product!(q, a[i], b[i]); end
#     r = Posit{32,2}(q)                 # the single rounding step

# (N,ES) pairs with a registered C++ quire.  Mirrors POSIT_QUIRE_REGISTRY in
# src/libuniversal_wrapper.cpp -- keep the two in sync.
const _POSIT_QUIRE_REGISTRY = [
    (8,  0,  "posit8_0",  UInt8),
    (8,  1,  "posit8_1",  UInt8),
    (8,  2,  "posit8_2",  UInt8),
    (12, 1,  "posit12_1", UInt16),
    (16, 1,  "posit16_1", UInt16),
    (16, 2,  "posit16_2", UInt16),
    (32, 2,  "posit32_2", UInt32),
    (19, 3,  "posit19_3", UInt32),
    (19, 2,  "posit19_2", UInt32),
    (64, 2,  "posit64_2", UInt64),
    (64, 3,  "posit64_3", UInt64),
]

const _QUIRE_PREFIX = Dict{Tuple{Int,Int},String}(
    (N, ES) => prefix for (N, ES, prefix, _) in _POSIT_QUIRE_REGISTRY
)

@inline function _quire_prefix(::Type{Posit{N,ES}}) where {N,ES}
    p = get(_QUIRE_PREFIX, (N, ES), nothing)
    p === nothing && error("No quire registered for Posit{$N,$ES}. Add it to " *
                           "POSIT_QUIRE_REGISTRY in src/libuniversal_wrapper.cpp " *
                           "(and _POSIT_QUIRE_REGISTRY in src/quire.jl) and rebuild.")
    return p
end
@inline _quire_prefix(::Type{Posit{N,ES,BT}}) where {N,ES,BT} = _quire_prefix(Posit{N,ES})

"""
    Quire(Posit{N,ES})

An exact accumulator for fused dot products of `Posit{N,ES}` values.  Accumulate
exact products with [`fma_product!`](@ref), reset with [`clear!`](@ref), and round
back to a posit with `Posit{N,ES}(q)`.  Posit-only and opt-in; ordinary posit
arithmetic is unaffected.
"""
mutable struct Quire{N,ES}
    ptr::Ptr{Cvoid}
    prefix::String
    function Quire{N,ES}() where {N,ES}
        prefix = _quire_prefix(Posit{N,ES})
        ptr = ccall(get_sym(Symbol(prefix * "_quire_new")), Ptr{Cvoid}, ())
        q = new{N,ES}(ptr, prefix)
        finalizer(_quire_free!, q)
        return q
    end
end

Quire(::Type{Posit{N,ES}}) where {N,ES}      = Quire{N,ES}()
Quire(::Type{Posit{N,ES,BT}}) where {N,ES,BT} = Quire{N,ES}()

function _quire_free!(q::Quire)
    if q.ptr != C_NULL
        ccall(get_sym(Symbol(q.prefix * "_quire_free")), Cvoid, (Ptr{Cvoid},), q.ptr)
        q.ptr = C_NULL
    end
    return nothing
end

"""
    clear!(q::Quire) -> q

Reset the quire to zero.
"""
function clear!(q::Quire)
    ccall(get_sym(Symbol(q.prefix * "_quire_clear")), Cvoid, (Ptr{Cvoid},), q.ptr)
    return q
end

"""
    quire_bits(Posit{N,ES}) -> Int

Total size of the `Posit{N,ES}` quire accumulator, in bits.
"""
quire_bits(::Type{Posit{N,ES}}) where {N,ES} =
    Int(ccall(get_sym(Symbol(_quire_prefix(Posit{N,ES}) * "_quire_bits")), Cint, ()))
quire_bits(::Type{Posit{N,ES,BT}}) where {N,ES,BT} = quire_bits(Posit{N,ES})

# Per-type methods: storage type BT is a literal here, so the ccall arg/return
# types are statically known (matching the scalar bridge's raw-IT ABI).
for (N, ES, prefix, BT) in _POSIT_QUIRE_REGISTRY
    P  = :(Posit{$N,$ES,$BT})    # concrete
    PU = :(Posit{$N,$ES})        # user-facing UnionAll

    @eval begin
        """
            fma_product!(q::Quire{$($N),$($ES)}, a, b) -> q

        Accumulate the exact product `a*b` into the quire (no rounding).
        """
        @inline function fma_product!(q::Quire{$N,$ES}, a::$P, b::$P)
            ccall(get_sym(Symbol($(prefix * "_quire_fma"))), Cvoid,
                  (Ptr{Cvoid}, $BT, $BT), q.ptr, a.data, b.data)
            return q
        end

        # Round the quire back to a posit (the single rounding step).
        @inline function $P(q::Quire{$N,$ES})
            bits = ccall(get_sym(Symbol($(prefix * "_quire_round"))), $BT,
                         (Ptr{Cvoid},), q.ptr)
            return $P(bits, true)
        end
        @inline $PU(q::Quire{$N,$ES}) = $P(q)

        # Typed kernel: whole accumulation loop runs C++-side, one ccall.
        function _fdp(::Type{$P}, a::AbstractVector, b::AbstractVector)
            n = length(a)
            aa = a isa Vector{$P} ? a : Vector{$P}(a)   # normalize to concrete, 1-based
            bb = b isa Vector{$P} ? b : Vector{$P}(b)
            bits = ccall(get_sym(Symbol($(prefix * "_fdp"))), $BT,
                         (Ptr{$P}, Ptr{$P}, Csize_t), aa, bb, n)
            return $P(bits, true)
        end
    end
end

"""
    fdp(a, b)

Exact fused dot product of two `Posit{N,ES}` vectors: accumulates `sum(a .* b)`
in the quire with no intermediate rounding, then rounds once.  Accepts vectors
of either concrete (`Posit{N,ES,BT}`) or parametric (`Posit{N,ES}`) element type.
"""
function fdp(a::AbstractVector{<:Posit}, b::AbstractVector{<:Posit})
    length(a) == length(b) ||
        throw(DimensionMismatch("fdp: vectors must have equal length"))
    Ta = _concretetype(eltype(a))
    Tb = _concretetype(eltype(b))
    Ta === Tb || error("fdp: both vectors must have the same Posit type; " *
                       "got $(eltype(a)) and $(eltype(b)).")
    return _fdp(Ta, a, b)
end

# Friendly errors for unregistered / non-posit inputs (specific methods above win).
fma_product!(q::Quire{N,ES}, a, b) where {N,ES} =
    error("fma_product!: a and b must both be Posit{$N,$ES}.")
fdp(a::AbstractVector, b::AbstractVector) =
    error("fdp (quire) is only available for Posit vectors; " *
          "got eltypes $(eltype(a)) and $(eltype(b)).")

"""
    quire_dot(a, b)

Alias for [`fdp`](@ref): the exact fused dot product of two `Posit{N,ES}` vectors.
"""
const quire_dot = fdp
