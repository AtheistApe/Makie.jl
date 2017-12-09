using Makie, GeometryTypes, Colors
scene = Scene()

scatter(scene, rand(10), rand(10), markersize = 0.1)
scatter(scene, rand(10), rand(10), markersize = 0.1)
center!(scene)
pos = [Point(50px, 50px), Point(600px, 600px)]
s = scatter(pos, markersize = 10mm, marker = :rect)

s[:markersize] = 10mm

s[:positions] = [Point(10px, 20px), Point(600px, 600px)]
minimum(Makie.Units.pixel_per_mm(scene))

scene[:theme][:scatter][:marker] = :cross
center!(scene)

x = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
    linesegment(linspace(1, 5, 100), rand(100), rand(100), linestyle = ls, linewidth = lw)
end
push!(x, scatter(linspace(1, 5, 100), rand(100), rand(100)))
center!(scene)

l = Makie.legend(x, ["attribute $i" for i in 1:4])
io = VideoStream(scene, homedir()*"/Desktop")
record(io) = (for i = 1:35; recordframe!(io); sleep(1/30); end);
l[:position] = (0, 1)
record(io)
l[:backgroundcolor] = RGBA(0.95, 0.95, 0.95)
record(io)
l[:strokecolor] = RGB(0.8, 0.8, 0.8)
record(io)
l[:gap] = 30
record(io)
l[:textsize] = 19
record(io)
l[:linepattern] = Point2f0[(0,-0.2), (0.5, 0.2), (0.5, 0.2), (1.0, -0.2)]
record(io)
l[:scatterpattern] = decompose(Point2f0, Circle(Point2f0(0.5, 0), 0.3f0), 9)
record(io)
l[:markersize] = 2f0
record(io)
finish(io, "mp4")

using Makie, Colors, GeometryTypes
GLAbstraction.DummyCamera <: GLAbstraction.Camera
scene = Scene()
cmap = collect(linspace(to_color(:red), to_color(:blue), 20))
l = Makie.legend(cmap, 1:4)
l[:position] = (1.0,1.0)

l[:textcolor] = :blue
l[:strokecolor] = :black
l[:strokewidth] = 1
l[:textsize] = 15
l[:textgap] = 5

using Makie
scene = Scene(resolution = (500, 500))
x = [0, 1, 2, 0]
y = [0, 0, 1, 2]
z = [0, 2, 0, 1]
color = [:red, :green, :blue, :yellow]
i = [0, 0, 0, 1]
j = [1, 2, 3, 2]
k = [2, 3, 1, 3]
indices = [1, 2, 3, 1, 3, 4, 1, 4, 2, 2, 3, 4]
m = mesh(x, y, z, indices, color = color)
m[:color] = [:blue, :red, :blue, :red]

using Makie, GeometryTypes

scene = Scene()
sub = Scene(scene, offset = Vec3f0(1, 2, 0))
scatter(sub, rand(10), rand(10), camera = :orthographic)
sub[:camera]
lines(sub, rand(10), rand(10), camera = :orthographic)
axis(linspace(0, 2, 4), linspace(0, 2, 4))
center!(scene)
sub[:offset] = Vec3f0(0, 0, 0)


using Makie, GeometryTypes

scene = Scene()

# create a subscene from which the next scenes you will plot
# `inherit` attributes. Need to add the attribute you care about,
# in this case the rotation
sub = Scene(scene, rotation = Vec4f0(0, 0, 0, 1))

meshscatter(sub, rand(30) + 1.0, rand(30), rand(30))
meshscatter(sub, rand(30), rand(30), rand(30) .+ 1.0)
r = linspace(-2, 2, 4)
Makie.axis(r, r, r)
center!(scene)

axis = Vec3f0(0, 0, 1)
io = VideoStream(scene, homedir()*"/Desktop/", "rotation")
for angle = linspace(0, 2pi, 100)
    sub[:rotation] = Makie.qrotation(axis, angle)
    recordframe!(io)
    sleep(1/15)
end
finish(io, "gif")

keys = (
    :lol, :pos, :test
)
positions, pos, test = get.(attributes, keys, scene)


function myvisual(scene, args, attributes)
    keys = (
        :positions, :color, :blah, shared...,
    )
    Scene(zip(keys, getindex.(attributes, keys))

end


using Makie, GeometryTypes


function plot(scene::S, A::AbstractMatrix{T}) where {T <: AbstractFloat, S <: Scene}
    N, M = size(A)
    sub = Scene(scene, scale = Vec3f0(1))
    attributes = Dict{Symbol, Any}()

    plots = map(1:M) do i
        lines(sub, 1:N, A[:, i])
    end
    labels = get(attributes, :labels) do
        map(i-> "y $i", 1:M)
    end

    lift_node(to_node(A), to_node(Makie.getscreen(scene).area)) do a, area
        xlims = (1, size(A, 1))
        ylims = extrema(A)
        stretch = Makie.to_nd(fit_ratio(area, (xlims, ylims)), Val{3}, 1)
        sub[:scale] = stretch
    end
    l = legend(scene, plots, labels)
    # Only create one axis per scene
    xlims = linspace(1, size(A, 1), min(N, 10))
    ylims = linspace(extrema(A)..., 5)
    a = get(scene, :axis) do
        xlims = (1, size(A, 1))
        ylims = extrema(A)
        area = Reactive.value(Makie.getscreen(scene).area)
        stretch = Makie.to_nd(fit_ratio(area, (xlims, ylims)), Val{3}, 1)
        axis(linspace((xlims .* stretch[1])..., 4), linspace((ylims .* stretch[2])..., 4))
    end
    center!(scene)
end

using Makie, GeometryTypes

scene = Scene()

x = (0.5rel, 0.5rel)

x .* Point2f0(0.5, 0.5)
StaticArrays.similar_type(NTuple{2, Float32}, Int)


Makie.VecLike{3, Float32}
Makie.Units.to_absolute(scene, x)
to_positions(scene, (rand(10) .* rel, rand(10) .* rel))

convert(Relative{Float64}, 1)

convert(NTuple{2, Relative{Float64}}, Tuple(Relative.(widths(scene))))

plot(scene, rand(11, 2))

using VisualRegressionTests


function test1(fn)
    srand(1234)
    scene = Scene(resolution = (500, 500))
    scatter(rand(10), rand(10))
    center!(scene)
    save(fn, scene)
end

cd(@__DIR__)

test1("test.png")

result = test_images(VisualTest(test1, "test.png"))




"""
To cut down on anonymous functions, let's create an explicit
closure to pass the current scene to the convert function
"""
struct ConvertFun{F, Backend}
    func::F
    scene::Scene{Backend}
end

(CF::ConvertFun)(value) = CF.func(CF.scene, value)



function default(
        scene::Scene, attributes::Void,
        parent::Symbol, attribute::Symbol,
        convert_func, default_value
    )
    scene[:theme, parent, attribute] = to_node(Signal(Any, default_value))
    default_value
end

function default(
        scene::Scene, attributes::Void,
        parent::Symbol, attribute::Symbol,
        convert_func
    )
    # No default value supplied - so we can't add anything to theme
    nothing
end

"""
Generate attribute docs
"""
function default(
        scene::Dict, attributes::Void,
        parent::Symbol, attribute::Symbol,
        convert_func, val = nothing # we don't care if there is no value
    )
    func = Symbol(convert_func)
    scene[attribute] = "Attribute `$attribute`, conversion function [`$func`](@ref)"
    val
end

"""
Default generation for non optional attributes.
"""
function default(
        scene::Scene, attributes::Scene,
        parent::Symbol, attribute::Symbol,
        convert_func
    )
    # First look in attributes
    val = get(attributes, attribute) do
        error("
            $attribute doesn't have a default, so it isn't optional. Please supply it!
            you will find more information what value it accepts in [`$(Symbol(conver_func))`](@ref) and
            possibly in the documentation of [`$(parend)`](@ref).
        ")
    end
    attributes[attribute] = to_node(val, ConvertFun(convert_func, scene))
    nothing
end

"""
Default generation for an attribute with a default in the theme
"""
function default(
        scene::Scene, attributes::Scene,
        parent::Symbol, attribute::Symbol,
        convert_func, val
    )
    # First look in attributes
    value = get(attributes, attribute) do
        # then in parent node of theme
        get(scene, :theme, parent, attribute) do
            # finally in the shared node of the theme
            get(scene, :theme, :shared, attribute) do
                error("
                    Can't find a default for attribute $attribute with parent $parent.
                    This is either a bug or you deleted the default for $attribute from the theme.
                ")
            end
        end
    end
    attributes[attribute] = to_node(value, ConvertFun(convert_func, scene))
end

function calculated(scene::Dict, args::Void, parent, attribute, convert_func, args::Void...)
    func = Symbol(convert_func)
    scene[attribute] = "Calculated attribute `$attribute`, conversion function [`$func`](@ref)"
end

function calculated(scene::Scene, args::Scene, parent, attribute, convert_func, args::AbstractNode...)
    # Attribute overwritten by user, no need to calculate it!
    value = if haskey(args, attribute)
        to_node(args[attribute])
    else
        # we need to calculate it from args - by conention, first arg is always the scene
        lift_node(convert_func, to_node(scene), args...)
    end
    scene[attribute] = value
    value
end

function shared_defaults(scene, args = nothing)
    @default shared = begin
        visible = default(scene, args, :shared, :visible, to_bool, true)
        model = calculated(scene, args, :shared, :model, to_modelmatrix, scale, offset, rotation)

        camera = to_camera(:auto)
        light = to_vec3s([Vec3f0(1.0), Vec3f0(0.1), Vec3f0(0.9), Vec3f0(20)])

        if haskeys(scene, args, :x, :y)

        elseif haskeys(scene, args, :position)

        end
    end
end

using GeometryTypes, EarCut
range = linspace(0, 2π, 400)
x = sin.(range); y = (x->sin(2x)).(range)

poly = GeometryTypes.split_intersections(Point2f0.(x, y))

faces = EarCut.triangulate.(map(x->[x], poly))
using Makie
scene = Scene()


w = glscreen(); @async renderloop(w)
mesh = GLNormalMesh(map(x-> Point3f0(x[1], x[2], 0), vcat(poly...)), faces)
_view(visualize(mesh))
GLAbstraction.center!(scene)

Pkg.add("Shapefile")
using Shapefile, FileIO
dir = "https://github.com/nvkelso/natural-earth-vector/raw/master/110m_physical/"
fn = "ne_110m_land.shp"
file = download(joinpath(dir, fn))
shp = open(file) do fd
    read(fd, Shapefile.Handle)
end
shp.shapes[1].points)
