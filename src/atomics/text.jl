struct TextBuffer{N}
    positions::GPUVector{Point{N, Float32}}
    offsets::GPUVector{Vec2f0}
    rotations::GPUVector{Vec4f0}
    colors::GPUVector{RGBAf0}
    uv_offset_width::GPUVector{Vec4f0}
    scale::GPUVector{Vec2f0}
    text::Vector{Char}
    robj::RenderObject
    range::Signal{Int}
    cursors
end

get_atlas(x::TextBuffer) = x.robj[:atlas]

function TextBuffer(pos::Point{N, <: AbstractFloat} = Point3f0(0)) where N
    positions = gpuvec(Point{N, Float32}[])
    offset = gpuvec(Vec2f0[])
    rotations = gpuvec(Vec4f0[])
    colors = gpuvec(RGBAf0[])
    uv_offset_width = gpuvec(Vec4f0[])
    scale = gpuvec(Vec2f0[])
    atlas = GLVisualize.get_texture_atlas()
    range = Signal(0)
    robj = visualize(
        (DISTANCEFIELD, positions.buffer),
        atlas = atlas,
        offset = offset.buffer,
        rotation = rotations.buffer,
        color = colors.buffer,
        uv_offset_width = uv_offset_width.buffer,
        scale = scale.buffer,
        distancefield = atlas.images,
        indices = range,
        boundingbox = Signal(AABB{Float32}())
    )
    TextBuffer{N}(
        positions,
        offset,
        rotations,
        colors,
        uv_offset_width,
        scale,
        Char[],
        robj.children[],
        range,
        nothing
    )
end

function Base.empty!(tb::TextBuffer{N}) where N
    resize!(tb.positions, 0)
    resize!(tb.offsets, 0)
    resize!(tb.rotations, 0)
    resize!(tb.colors, 0)
    resize!(tb.uv_offset_width, 0)
    resize!(tb.scale, 0)
    push!(tb.range, 0)
    Reactive.set_value!(tb.robj.boundingbox, AABB{Float32}())
    push!(tb.robj.boundingbox, AABB{Float32}())
    return
end




function Base.append!(tb::TextBuffer, startpos::StaticVector{N}, str::String, scale, color, rot, align, font = GLVisualize.defaultfont()) where N
    atlas = get_atlas(tb)
    pos = Point{N, Float32}(startpos)
    rscale = Float32(scale)
    position = GLVisualize.calc_position(str, Point2f0(0), rscale, font, atlas)
    toffset = GLVisualize.calc_offset(str, rscale, font, atlas)
    aoffsetvec = Vec2f0(alignment2num.(align))
    aoffset = align_offset(rot, Point2f0(0), position[end], atlas, rscale, font, aoffsetvec)
    aoffsetn = Point{N, Float32}(to_nd(aoffset, Val{N}, 0f0))
    uv_offset_width = Vec4f0[GLVisualize.glyph_uv_width!(atlas, c, font) for c = str]
    scale = Vec2f0[GLVisualize.glyph_scale!(atlas, c, font, rscale) for c = str]
    position = map(position) do p
        pn = qmul(rot, Point{N, Float32}(to_nd(p, Val{N}, 0f0)))
        pn .+ (pos .+ aoffsetn)
    end

    append!(tb.positions, position)
    append!(tb.offsets, Vec2f0.(toffset))
    append!(tb.rotations, fill(rot, length(position)))
    append!(tb.colors, fill(to_color(color), length(position)))
    append!(tb.uv_offset_width, uv_offset_width)
    append!(tb.scale, scale)

    bb = value(tb.robj.boundingbox)
    for (s, pos) in zip(scale, position)
        pos3d = Vec{3, Float32}(to_nd(pos, Val{3}, 0))
        bb = update(bb, pos3d)
        bb = update(bb, pos3d .+ Vec{3, Float32}(to_nd(s, Val{3}, 0)))
    end
    push!(tb.robj.boundingbox, bb)
    Reactive.set_value!(tb.robj.boundingbox, bb)
    push!(tb.range, length(tb.positions))
    return
end

function align_offset(rot, startpos, lastpos, atlas, rscale, font, align)
    xscale, yscale = GLVisualize.glyph_scale!('X', rscale)
    xmove = (lastpos-startpos)[1] + xscale
    xmove, yscale, z = qmul(rot, Vec3f0(xmove, yscale, 0))
    if isa(align, GeometryTypes.Vec)
        return -Vec2f0(xmove, yscale) .* align
    elseif align == :top
        return -Vec2f0(xmove/2f0, yscale)
    elseif align == :right
        return -Vec2f0(xmove, yscale/2f0)
    else
        error("Align $align not known")
    end
end

function alignment2num(x::Symbol)
    (x in (:hcenter, :vcenter)) && return 0.5f0
    (x in (:left, :bottom)) && return 0.0f0
    (x in (:right, :top)) && return 1.0f0
    0.0f0 # 0 default, or better to error?
end


function to_gl_text(string, startpos::VecLike{N, T}, textsize, font, align, rot) where {N, T}
    atlas = GLVisualize.get_texture_atlas()
    pos = Point{N, Float32}(startpos)
    rscale = Float32(textsize)
    positions2d = GLVisualize.calc_position(string, Point2f0(0), rscale, font, atlas)
    toffset = GLVisualize.calc_offset(string, rscale, font, atlas)
    aoffsetvec = Vec2f0(alignment2num.(align))
    aoffset = align_offset(rot, Point2f0(0), positions2d[end], atlas, rscale, font, aoffsetvec)
    aoffsetn = Point{N, Float32}(to_nd(aoffset, Val{N}, 0f0))
    uv_offset_width = Vec4f0[GLVisualize.glyph_uv_width!(atlas, c, font) for c = string]
    scale = Vec2f0[GLVisualize.glyph_scale!(atlas, c, font, rscale) for c = string]
    positions = map(positions2d) do p
        pn = qmul(rot, Point{N, Float32}(to_nd(p, Val{N}, 0f0)))
        pn .+ (pos .+ aoffsetn)
    end
    positions, toffset, uv_offset_width, scale
end


immutable TextAttributes
    size::Float32
    color::RGBAf0
    rotation::Vec4f0
    alignment::Vec2f0
    font::Font
end

function TextAttributes(
        scene = global_scene();
        size = 14,
        color = :black,
        rotation = Vec4f0(0, 0, 0, 1),
        alignment = (:left, :bottom),
        font = "default",
    )
    TextAttributes(
        to_float(scene, size),
        to_color(scene, color),
        to_rotation(scene, rotation),
        to_textalign(scene, alignment),
        to_font(scene, font),
    )
end

immutable Text
    string::String
    attributes::TextAttributes
end


Text(x; kw_args...) = Text(string(x), TextAttributes(; kw_args...))

function text(
        scene::Scene,
        text,
        attributes::Attributes
    )
    attributes[:text] = text
    attributes = text_defaults(scene, attributes)
    liftkeys = (:text, :position, :textsize, :font, :align, :rotation)
    gl_text = to_signal(lift_node(to_gl_text, getindex.(attributes, liftkeys)...))
    # unpack values from the one signal:
    positions, offset, uv_offset_width, scale = map((1, 2, 3, 4)) do i
        map(getindex, gl_text, Signal(i))
    end

    atlas = GLVisualize.get_texture_atlas()
    keys = [:color, :strokecolor, :strokewidth, :rotation]
    signals = to_typed_signal.(getindex.(attributes, keys))

    attributes.visual[] = visualize(
        (DISTANCEFIELD, positions),
        color = signals[1],
        stroke_color = signals[2],
        stroke_width = signals[3],
        rotation = signals[4],
        scale = scale,
        offset = offset,
        uv_offset_width = uv_offset_width,
        distancefield = atlas.images
    ).children[]

    insert_scene!(scene, attributes)
end
