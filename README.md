# CGP.jl

[Cartesian Genetic Programming](http://www.cartesiangp.co.uk/) for
[julia](http://julialang.org/).

This implementation of CGP includes various extensions,
including
[RCGP](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.667.5178&rep=rep1&type=pdf),
[MTCGP](https://www.researchgate.net/profile/Juxi_Leitner/publication/224041240_MT-CGP_Mixed_type_cartesian_genetic_programming/links/0912f50535e6484c67000000/MT-CGP-Mixed-type-cartesian-genetic-programming.pdf),
[genetic crossover](https://s3.amazonaws.com/academia.edu.documents/43944049/A_new_crossover_technique_for_Cartesian_20160321-16124-j8wfpv.pdf?AWSAccessKeyId=AKIAIWOWYYGZ2Y53UL3A&Expires=1528918353&Signature=wWWo8mJebTDPVuSCUYL7303G7ME%3D&response-content-disposition=inline%3B%20filename%3DA_new_crossover_technique_for_Cartesian.pdf),
and more.

Development is still ongoing, so be warned that major changes might happen.
Stable resources in other languages can be found on
the [CGP site](https://www.cartesiangp.com/).

## Installation

Install [Julia v1.0](https://julialang.org/downloads/).

## Project dependencies

This project was created with roughly this configuration:

```julialang
julia> ]
pkg> activate .
(CGP.jl) pkg> add "https://github.com/d6y/ArcadeLearningEnvironment.jl.git"
(CGP.jl) pkg> add PaddedViews Images Distributions YAML ArgParse TestImages Colors QuartzImageIO
(CGP.jl) pkg> add LightGraphs MetaGraphs TikzGraphs ImageTransformations ImageMagick
(CGP.jl) pkg> add SharedArrays Printf Distributed
(CGP.jl) pkg> build
(CGP.jl) pkg> <delete><delete>
```

You should not need to re-run all those commands, just:

```
$ cd CGP.jl
$ julia --project=.
julia> ]
pkg> build
pkg> <delete>
julia> exit()
```

## Tests

`CGP.jl` comes with exhaustive tests which can offer examples of detailed usage
of the different genetic operators and CGP extensions. To run all tests, use

```bash
julia --project=. run_tests.jl
```

**Note** you may currently need to run the tests a few times to get through them successfully.

## Examples

Four different examples are found in the `experiments` folder:

### XOR

XOR evolves a function to compute the `xor` function over `nsamples` number of
randomly generated bits strings of `nbits` length. This can be run simply with

```bash
julia --project=. experiments/xor.jl
```

but various options can be set using command line arguments:

```bash
julia --project=. experiments/xor.jl --nbits 5 --nsamples 30
```

### Data tasks

Classification and regression can be performed with the `data.jl` script. Two
example datasets have been provided in the `data`
directory:
[Wisconsin Breast Cancer](https://archive.ics.uci.edu/ml/datasets/Breast+Cancer+Wisconsin+(Diagnostic))
and [Abalone](http://archive.ics.uci.edu/ml/datasets/Abalone). The first two
lines specify the number of inputs and outputs, and the second two lines specify
the number of training samples and test samples. Data are read in the order
provided in the files, and must be normalized between -1.0 and 1.0 before use in
`data.jl`. To change any of the data preparation steps, modify the `read_data`
function in `data.jl`.

Classification is the default problem and uses accuracy as the evolutionary
fitness. To run classification on the Breast Cancer set, use:

```bash
julia --project=. experiments/data.jl --data data/cancer.dt --log cancer.log
```

Regression can be specified as an option on the command line:

```bash
julia --project=. experiments/data.jl --data data/abalone.dt --log abalone.log --fitness regression
```

### OpenAI gym environments

`gym.jl` uses [PyCall.jl](https://github.com/JuliaPy/PyCall.jl) to evolve CGP
programs for the
[OpenAI gym environments](https://gym.openai.com/envs/).
[pybullet](https://github.com/bulletphysics/bullet3) environments are also
included as an alternative to the mujoco environments used by OpenAI. Please see
the PyCall.jl documentation for setting up a python environment with the
necessary packages (`gym` and `pybullet`).

For example, to install gym globally:

```
$ pip install gym
$ pip install pybullet
$ PYTHON=`which python` julia
julia> ]
pkg> add PyCall
pkg> build PyCall
```

To evolve a program for the `MountainCarContinuous-v0` environment, run:

```bash
julia --project=. experiments/gym.jl --total_evals 200 --seed 1
```

### Atari

`atari.jl`
uses
[`ArcadeLearningEnvironment.jl`](https://github.com/nowozin/ArcadeLearningEnvironment.jl)
to evolve programs which play Atari games. This is a more complex example, as it
uses Mixed-Type CGP by default (program inputs are RGB Arrays, and outputs are
scalar actions.) ROMs are available from
[Atari-py](https://github.com/openai/atari-py/tree/master/atari_py/atari_roms).

Create `rom_files` folder:

```bash
mkdir ~/.julia/packages/ArcadeLearningEnvironment/x1HHl/deps/rom_files
```

...and copy ROM files there.

Once ROMs have been configured, a CGP agent can be evolved using:

```bash
julia --project=. experiments/atari.jl --id boxing
```

This requires a long runtime. Parallelizing evaluations is a currently planned
improvement: see [this issue](https://github.com/d9w/CGP.jl/issues/2).

## Running `irace`

Edit `target-runner` and adjust `EXE` and `JULIA_LOAD_PATH`. Then:

```
$ cd irace_tuning
$ irace --check --parallel 2
```

...and check the `irace_logs` folder for logs.

Review the settings of `MAX_FRAMES` and `TOTAL_EVALS` in the `target-runner` script.


## Configuration

Configuration is handled by `src/config.jl`. Configurable options are read in
through YAML files (an example being `cfg/test.yaml`) and then are accessed in
the `CGP.Config` module. YAML files are loaded into configuration by running

```julia
CGP.Config.init(file)
```

Redefinition of a configuration value will overwrite the previous value, so be
careful about ordering of configuration files. The example files also show usage
of the `CGP.Config.add_arg_settings!` function, which allows for all
configuration values to be passed via the command line.

### Function set configuration

All node functions are contained in the `CGP.Config.functions` array and are
populated in the configuration files. The syntax for function definitions allows
for mixed type CGP by defining a function for both scalar and **vector** node
inputs. The function ordering is:

- (x, y)
- (x, **y**)
- (**x**, y)
- (**x**, **y**)

As shorthand, a single function can be specified for all four input types. If
two function definitions are provided, the first will apply to the two first two
input types where x is a scalar, and the second definition will apply to the
second two input types. `cfg/atari.yaml` demonstrates many different function
definitions.

## Attribution

A comprehensive review of genetic operators for CGP is underway and is intended
to be the reference for this library, but until then a link to this repository
would be appreciated in any works which use it.
