"""
calculates how much `child` needs to move to not touch `parent`
"""
function move_from_touch(
        parent::GeometryPrimitive{N, T}, child::GeometryPrimitive{N},
        pad::Vec{N}
    ) where {N, T}
    pmini, cmini = minimum(parent), minimum(child) .- pad
    pmaxi, cmaxi = maximum(parent), maximum(child) .+ pad

    move = ntuple(Val{N}) do i
        posdir = ifelse(cmini[i] < pmini[i], (pmini[i] - cmini[i]), zero(T)) #always positive
        negdir = ifelse(cmaxi[i] > pmaxi[i], (pmaxi[i] - cmaxi[i]), zero(T)) #always minus
        ifelse(posdir > abs(negdir), posdir, negdir) # move in the bigger direction
    end
    Vec{N, T}(move)
end

"""
Moves `child` so that it doesn't touch parent. Leaves a gap to parent defined by `pad`.
"""
function dont_touch(
        parent::GeometryPrimitive{N}, child::GeometryPrimitive{N},
        pad::Vec{N}
    ) where N
    child + move_from_touch(parent, child, pad)
end



"""
    fit_factor_stretch(rect, lims::NTuple{N}) where N

Calculates the stretch factor to fill `rect` in all dimension.
Returns a stretch `N` dimensional fit factor.
"""
function fit_factor_stretch(rect, lims::NTuple{N, Any}) where N
    w = widths(rect)
    stretches = ntuple(Val{N}) do i
        from, to = lims[i]
        w[i] / abs(to - from)
    end
    stretches
end

"""
    fit_factor(rect, lims::NTuple{N}) where N

Calculates the scaling one needs to apply to lims to fit `rect` without changing aspect ratio.
Returns float scaling and the full strech as given by [`fit_factor_stretch`](@ref)
"""
function fit_factor(rect, lims::NTuple{N, Any}) where N
    stretches = fit_factor_stretch(rect, lims)
    minimum(stretches), stretches
end


"""
    fit_ratio(rect, lims)

Calculates the ratio one needs to stretch `lims` in order to get the same aspect ratio
"""
function fit_ratio(rect, lims)
    s, stretches = fit_factor(rect, lims)
    stretches ./ s
end





# using GeometryTypes
#
# using Base.Test
#
# x = HyperRectangle(Vec3f0(-2), Vec3f0(2))
# c = HyperRectangle(Vec3f0(-2), Vec3f0(2))
# @test dont_touch(x, c, Vec3f0(0)) == x
# c = HyperRectangle(Vec3f0(-2), Vec3f0(1.5))
# @test dont_touch(x, c, Vec3f0(0.25)) == HyperRectangle(Vec3f0(-1.75), Vec3f0(1.5))
# c = HyperRectangle(Vec3f0(0), Vec3f0(1, 1.75, 1))
# @test dont_touch(x, c, Vec3f0(0.25)) == HyperRectangle(Vec3f0(-1.25, -2.0, -1.25), Vec3f0(1.0, 1.75, 1.0))
# x = SimpleRectangle(0, 0, 1, 1)
# SimpleRectangle(HyperRectangle(x))
