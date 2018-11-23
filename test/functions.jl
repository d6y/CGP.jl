using Test
using CGP

const global D = 2
const global smax = 1000
const global snum = 4

files = ["cfg/default.yaml", "cfg/base.yaml", "cfg/test.yaml", "cfg/classic.yaml", "cfg/atari.yaml"]

function test_inps(f, inps)
    out = f(inps...)
    @test all(out == f(inps...))
    minout = minimum(out); maxout = maximum(out)
    # @printf("%0.2f, %0.2f, %s, ", minout, maxout, typeof(out))
    @test (minout >= -1.0) && (maxout <= 1.0)
end


@testset "Functions" begin
    for file in files
        CGP.Config.init(file)
        for f in CGP.Config.functions
            @testset "$file $f" begin
                println("$file $f")
                for d in 1:D
                    for s in Int64.(round.(range(1, stop=smax, length=snum)))
                        for cval in -1:1:1
                            cval = Float64(cval)
                            test_inps(f, [cval, cval, cval])
                            test_inps(f, [cval,
                                          cval * ones(repeat([s], inner=d)...),
                                          cval])
                            test_inps(f, [cval * ones(repeat([s], inner=d)...),
                                          cval, cval])
                            for dy in 1:D
                                test_inps(f, [cval * ones(repeat([s], inner=d)...),
                                              cval * ones(repeat([s], inner=dy)...),
                                              cval])
                            end
                        end
                        test_inps(f, [2*rand()-1,
                                      2*rand()-1,
                                      2*rand()-1])
                        test_inps(f, [2*rand()-1,
                                      2*rand(repeat([s], inner=d)...) .- 1,
                                      2*rand()-1])
                        test_inps(f, [2*rand(repeat([s], inner=d)...) .- 1,
                                      2*rand()-1,
                                      2*rand()-1])
                        for dy in 1:D
                            test_inps(f, [2*rand(repeat([s], inner=d)...) .- 1,
                                          2*rand(repeat([s], inner=dy)...) .- 1,
                                          2*rand()-1])
                        end
                    end
                end
            end
        end
        CGP.Config.reset()
    end
end
