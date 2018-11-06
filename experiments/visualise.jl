using ArcadeLearningEnvironment
using CGP
using Logging
using ArgParse
using LightGraphs
using MetaGraphs
using TikzPictures
using TikzGraphs
import Images

CGP.Config.init("cfg/atari.yaml")

# The idea here is to play a game, recording the outputs at each frame to a file.
# Later, we can map these values on to the graph diagram to show which notes are active.

function play_atari(c::Chromosome, id::String, seed::Int64; render::Bool=true, folder::String="vis", max_frames=18000)
    game = Game(id, seed)
    seed_reset = rand(0:100000)
    srand(seed)
    reward = 0.0
    frames = 0
    p_action = game.actions[1]
    outputs = zeros(Int64, c.nout)
    while ~game_over(game.ale)
        ins = get_rgb(game)
        output = process(c, ins)
        outputs[indmax(output)] += 1
        action = game.actions[indmax(output)]
        reward += act(game.ale, action)
        if rand() < 0.25
            reward += act(game.ale, action) # repeat action here for seeding
        end
        if render
            # Save node outputs: [nin + num_nodes]
            node_values = map(n -> mean(n.output), c.nodes)
            data_filename = string(folder, "/", @sprintf("frame_%06d.dat", frames))
            writedlm(data_filename, node_values)

            # Save screen
            screen = draw(game)
            filename = string(folder, "/", @sprintf("frame_%06d.png", frames))
            Images.save(filename, screen)
        end
        frames += 1
        if frames > max_frames
            Logging.debug(string("Termination due to frame count on ", id))
            break
        end
    end
    close!(game)
    srand(seed_reset)
    reward, outputs, frames
end

# Convert node value to a [0,100] intensity from [-1,+1]
# TODO: maybe scale +/- 0.6 ? Most values < 0.06
function to_brightness(o::Float64)::Int64
    max(1, min(Int64(ceil(100 * abs(o) / 0.06 )), 100))
end

# Heat map for output values: red is positive; blue is negative
function to_colour(o::Float64)::String
    colour = if o < 0 "blue" else "red" end
    intensity = to_brightness(o)
    "$(colour)!$(intensity)"
end

if ~isinteractive()
    include("../graphing/graph_utils.jl")

    seed = 1
    id = "space_invaders"
    nout = 6
    nin = 3
    best = [0.77587, 0.302057, 0.100473, 0.456112, 0.556381, 0.909971, 0.161626, 0.220115, 0.683891, 0.233102, 0.773288, 0.20406, 0.460551, 0.81571, 0.7775, 0.043036, 0.314735, 0.929019, 0.581319, 0.66896, 0.833001, 0.164236, 0.139248, 0.174569, 0.28283, 0.462935, 0.844797, 0.840508, 0.0833296, 0.624793, 0.0239489, 0.686209, 0.663202, 0.790382, 0.346841, 0.852841, 0.345038, 0.654867, 0.758165, 0.900792, 0.451519, 0.646355, 0.550993, 0.637878, 0.0427992, 0.791433, 0.24563, 0.151521, 0.814863, 0.228201, 0.17336, 0.369152, 0.138918, 0.807239, 0.0514069, 0.511976, 0.105074, 0.0593427, 0.504444, 0.93147, 0.15469, 0.564135, 0.721632, 0.524829, 0.0429113, 0.339768, 0.851035, 0.299041, 0.134725, 0.116661, 0.75312, 0.138525, 0.511349, 0.762911, 0.795444, 0.759715, 0.344518, 0.915176, 0.695177, 0.595276, 0.519596, 0.470222, 0.0411111, 0.400529, 0.153174, 0.705262, 0.123912, 0.345433, 0.665689, 0.347177, 0.639935, 0.564514, 0.993248, 0.373427, 0.874992, 0.585536, 0.429306, 0.939239, 0.169165, 0.309779, 0.130988, 0.00353356, 0.5713, 0.597851, 0.015378, 0.201956, 0.114764, 0.0613365, 0.24993, 0.815978, 0.960831, 0.447812, 0.24311, 0.856119, 0.144423, 0.125129, 0.616783, 0.279554, 0.33595, 0.684937, 0.624167, 0.898498, 0.100128, 0.511807, 0.603125, 0.190602, 0.599064, 0.394529, 0.379346, 0.707586, 0.523366, 0.136358, 0.253278, 0.0709987, 0.198134, 0.144581, 0.13145, 0.33256, 0.24035, 0.863135, 0.805235, 0.691256, 0.00549689, 0.547222, 0.368444, 0.296776, 0.436715, 0.54215, 0.960148, 0.793456, 0.62295, 0.346732, 0.56168, 0.612401, 0.544475, 0.343629, 0.704173, 0.503632, 0.185509, 0.862941, 0.778049, 0.116072, 0.348409, 0.5403, 0.104132, 0.583087, 0.760465, 0.364393, 0.980475]

    srand(seed)

    c = CGPChromo(best, nin, nout)

    # Play game, recording frames and node outputs to files
    folder = string("frames/", id, "_", seed)
    mkpath(folder)
    (reward, out_counts, frames) = play_atari(c, id, seed, render=true, folder=folder)
    println("Total reward: $reward in $frames frames.")

    # Draw the graph, as usual:
    new_genes = deepcopy(c.genes)
    for o in 1:nout
        if out_counts[o] == 0.0
            new_genes[nin+o] = 0.00001
        end
    end
    active_outputs = out_counts .> 0
    chromo2 = CGPChromo(new_genes, nin, nout)
    file =  string(folder, "/", id, "_", seed, ".pdf");
    graph = to_graph(chromo2, active_outputs=active_outputs)
    names = map(x->get_prop(graph, x, :name), 1:nv(graph))
    t = TikzGraphs.plot(graph.graph, names)
    TikzPictures.save(TikzPictures.PDF(file), t)

    # Draw the chromosome for each frame, using colour to signal node output values
    actives = [n.active for n in c.nodes]
    actives[1:c.nin] = true
    vids = find(actives)

    for f in 0:(frames-1)
      data_filename = string(folder, "/", @sprintf("frame_%06d.dat", f))
      node_colours = map(to_colour, readdlm(data_filename))

      styles = Dict(map(i-> i => "fill=$(node_colours[vids[i]])", 1:nv(graph)))
      plot = TikzGraphs.plot(graph.graph, names, node_style="draw, rounded corners", node_styles=styles) 
      png_filename = string(folder, "/", @sprintf("node_%06d.pdf", f))
      TikzPictures.save(PDF(png_filename), plot)
    end

    # Rather than scale down graphs, maybe scale up (or box) the video?
    # mogrify -format png -resize 160x210 node*.pdf
    # convert -quality 100 node*.png nodes.mpeg
end
