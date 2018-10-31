using LightGraphs
using MetaGraphs
using CGP
using TikzGraphs
using TikzPictures

CGP.Config.init("cfg/test.yaml")

function example_graph()
    fg = MetaDiGraph(SimpleDiGraph())
    nin = 3; nout = 2
    add_vertices!(fg, nin + nout + 3)
    types = [0*ones(nin); 2*ones(3); 1*ones(nout)]
    for i in eachindex(types)
        set_prop!(fg, i, :type, types[i])
    end
    set_prop!(fg, 4, :function, CGP.Config.f_sum)
    set_prop!(fg, 4, :type, 2)
    set_prop!(fg, 4, :name, "fsum")
    add_edge!(fg, Edge(1, 4))
    set_prop!(fg, 1, 4, :ci, 1)
    add_edge!(fg, Edge(2, 4))
    set_prop!(fg, 2, 4, :ci, 2)
    set_prop!(fg, 5, :function, CGP.Config.f_mult)
    set_prop!(fg, 5, :name, "fmult")
    add_edge!(fg, Edge(3, 5))
    set_prop!(fg, 3, 5, :ci, 1)
    add_edge!(fg, Edge(4, 5))
    set_prop!(fg, 4, 5, :ci, 2)
    set_prop!(fg, 6, :function, CGP.Config.f_aminus)
    set_prop!(fg, 6, :name, "aminus")
    add_edge!(fg, Edge(1, 6))
    set_prop!(fg, 1, 6, :ci, 1)
    add_edge!(fg, Edge(3, 6))
    set_prop!(fg, 3, 6, :ci, 2)
    add_edge!(fg, Edge(5, 7))
    set_prop!(fg, 5, 7, :ci, 0)
    add_edge!(fg, Edge(6, 8))
    set_prop!(fg, 6, 8, :ci, 0)

    set_prop!(fg, 1, :name, "in1")
    set_prop!(fg, 2, :name, "in2")
    set_prop!(fg, 3, :name, "in3")
    set_prop!(fg, 7, :name, "out1")
    set_prop!(fg, 8, :name, "out1")

    set_prop!(fg, 1, :colour, "blue!0")
    set_prop!(fg, 2, :colour, "blue!100")
    set_prop!(fg, 3, :colour, "blue!70")
    set_prop!(fg, 4, :colour, "blue!60")
    set_prop!(fg, 5, :colour, "blue!40")
    set_prop!(fg, 6, :colour, "blue!20")
    set_prop!(fg, 7, :colour, "blue!10")
    set_prop!(fg, 8, :colour, "red!10")
   
    # max(1, min(Int64(ceil(100 * abs(-1.5) / 2)), 100))

    fg
end

function example_pdf()
    mg = example_graph()
    names = map(x->get_prop(mg, x, :name), 1:nv(mg))
    styles =  Dict(map(x-> x => "fill=$(get_prop(mg, x, :colour))", 1:nv(mg)))
    t = TikzGraphs.plot(mg.graph, names, node_style="draw, rounded corners", node_styles=styles)
    TikzPictures.save(TikzPictures.PDF("example.pdf"), t)
end

