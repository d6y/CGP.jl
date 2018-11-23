using CGP
using Logging
using ArgParse
using Random
using DelimitedFiles
using Printf

function read_data(dfile::String)
    df = open(dfile, "r")
    meta = [Meta.parse(split(readline(df), ' ')[2]) for i=1:4]
    data = Float64.(readdlm(dfile, ' ', skipstart=4))
    training = data[1:meta[3], :]
    test = data[meta[3] .+ (1:meta[4]), :]
    meta[1], meta[2], copy(training'), copy(test')
end

function classify(c::Chromosome, data::Array{Float64}, nin::Int64, nout::Int64)
    accuracy = 0
    nsamples = size(data, 2)
    for d in 1:nsamples
        outputs = process(c, data[1:nin, d])
        if argmax(outputs) == argmax(data[nin .+ (1:nout), d])
            accuracy += 1
        end
    end
    accuracy /= nsamples
    accuracy
end

function regression(c::Chromosome, data::Array{Float64}, nin::Int64, nout::Int64)
    error = 0
    nsamples = size(data, 2)
    for d in 1:nsamples
        outputs = process(c, data[1:nin, d])
        for p in eachindex(outputs)
            error += (outputs[p] - data[nin+p, d])^2
        end
    end
    error /= nsamples
    -error
end

function get_args()
    s = ArgParseSettings()

    @add_arg_table(
        s,
        "--seed", arg_type = Int, default = 0,
        "--data", arg_type = String, required = true,
        "--log", arg_type = String, required = true,
        "--fitness", arg_type = String, default = "classify",
        "--ea", arg_type = String, default = "oneplus",
        "--chromosome", arg_type = String, default = "CGPChromo",
        "--cfg", arg_type = String, required = false
    )

    CGP.Config.add_arg_settings!(s)
end

args = parse_args(get_args())

CGP.Config.init("cfg/base.yaml")
CGP.Config.init("cfg/classic.yaml")
if args["cfg"] != nothing
    CGP.Config.init(args["cfg"])
end

CGP.Config.init(Dict([k=>args[k] for k in setdiff(
    keys(args), ["seed", "data", "log", "fitness", "ea",
                 "chromosome", "cfg"])]...))

Random.seed!(args["seed"])
global_logger(SimpleLogger(open(args["log"], "a+")))
nin, nout, train, test = read_data(args["data"])
fitness = eval(Meta.parse(args["fitness"]))
ea = eval(Meta.parse(args["ea"]))
ctype = eval(Meta.parse(args["chromosome"]))

fit = x->fitness(x, train, nin, nout)
refit = x->fitness(x, test, nin, nout)
maxfit, best = ea(nin, nout, fit; seed=args["seed"], ctype=ctype,
                  id=args["data"])

best_ind = ctype(best, nin, nout)
test_fit = fitness(best_ind, test, nin, nout)
@info(@sprintf("T: %d %0.8f %0.8f %d %d %s %s",
                      args["seed"], maxfit, test_fit,
                      sum([n.active for n in best_ind.nodes]),
                      length(best_ind.nodes), args["ea"], args["chromosome"]))

@info(@sprintf("E%0.8f", -maxfit))
