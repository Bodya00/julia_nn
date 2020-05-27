using HDF5
using Random
using LinearAlgebra
using Statistics
using BenchmarkTools
using CSV



abstract type AbstractLoss end
struct BinaryCrossentropyLoss <: AbstractLoss end
function forward(::BinaryCrossentropyLoss, Y::Array{Float64}, A::Array{Float64})
    (-(Y * log.(A .+ 1.0e-10)') .- ((1 .- Y) * log.((1+1.0e-10) .- A)'))/ size(Y)[2]
end
function backward(::BinaryCrossentropyLoss, Y::Array{Float64}, A::Array{Float64})
    -((Y ./ A) - ((1 .- Y) ./ (1 .- A)))
end

struct MeanAbsoluteError <: AbstractLoss end
function forward(::BinaryCrossentropyLoss, Y::Array{Float64}, A::Array{Float64})
    (-(Y * log.(A .+ 1.0e-10)') .- ((1 .- Y) * log.((1+1.0e-10) .- A)'))/ size(Y)[2]
end
function backward(::BinaryCrossentropyLoss, Y::Array{Float64}, A::Array{Float64})
    -((Y ./ A) - ((1 .- Y) ./ (1 .- A)))
end

abstract type AbstractLayer end
abstract type AbstractActivationLayer <: AbstractLayer end

mutable struct SigmoidLayer <: AbstractActivationLayer
    last_input          ::Array{Float64, 2}
    SigmoidLayer() = new(Array{Float64, 2}(undef, 0, 0))
end
function forward(layer::SigmoidLayer, X::Array{Float64, 2}, build_graph::Val{true})
    layer.last_input = X
    forward(layer, X, Val(false))
end
function forward(layer::SigmoidLayer, X::Array{Float64, 2}, build_graph::Val{false}=Val(false))
    1 ./(1 .+ exp.(-X))
end
function backward(layer::SigmoidLayer, dZ::Array{Float64, 2})
    forward_result = forward(layer, layer.last_input)
    dZ .* forward_result .* (1 .- forward_result)
end

mutable struct ReLULayer <: AbstractActivationLayer
    last_input          ::Array{Float64, 2}
    ReLULayer() = new(Array{Float64, 2}(undef, 0, 0))
end
function forward(layer::ReLULayer, X::Array{Float64, 2}, build_graph::Val{true})
    layer.last_input = X
    forward(layer, X, Val(false))
end
function forward(layer::ReLULayer, X::Array{Float64, 2}, build_graph::Val{false}=Val(false))
    max.(0, X)
end
function backward(layer::ReLULayer, dZ::Array{Float64, 2})
    dZ[layer.last_input .<= 0] .= 0
    dZ
end


mutable struct LinearLayer <: AbstractLayer
    weights                         ::Array{Float64, 2}
    biases                          ::Array{Float64, 1}
    last_input                      ::Array{Float64, 2}

    function LinearLayer(weights::Array{Float64, 2}, biases::Array{Float64, 1})
        new(weights, biases)
    end
end

function LinearLayer(length_in::Int64, length_out::Int64)
    weights = randn(Float64, length_out, length_in) / sqrt(length_in)
    biases = zeros(Float64, length_out)
    LinearLayer(weights, biases)
end

function LinearLayer(length_in::Int64, length_out::Int64, random_seed::Int64)
    Random.seed!(random_seed)
    layer = LinearLayer(weights, biases)
    Random.seed!()
    layer
end

get_n_samples(layer::LinearLayer) = size(layer.last_input)[2]

function forward(layer::LinearLayer, X::Array{Float64, 2}, build_graph::Val{true})
    layer.last_input = X
    forward(layer, X, Val(false))
end
function forward(layer::LinearLayer, X::Array{Float64, 2}, build_graph::Val{false}=Val(false))
    layer.weights * X .+ layer.biases
end

function calc_weights_gradient(layer::LinearLayer, gradient::Array{Float64, 2})
    (gradient * layer.last_input') / size(layer.last_input)[2]
end

function calc_biases_gradient(layer::LinearLayer, gradient::Array{Float64, 2})
    sum(gradient, dims=2) / size(layer.last_input)[2]
end

function calc_input_gradient(layer::LinearLayer, gradient::Array{Float64, 2})
    layer.weights' * gradient
end

function update_weights(layer::LinearLayer, gradient::Array{Float64, 2})
    layer.weights -= gradient
end

function update_biases(layer::LinearLayer, gradient::Array{Float64, 2})
    layer.biases -= reshape(gradient, (:,))
end

function backward(layer::LinearLayer, gradient::Array{Float64, 2})
    input_gradient = calc_input_gradient(layer, gradient)
    dW = calc_weights_gradient(layer, gradient)
    update_weights(layer, dW)
    db = calc_biases_gradient(layer, gradient)
    update_biases(layer, db)
    input_gradient
end

abstract type AbstractNeuralNetwork end

struct NeuralNetwork
    layers::Vector{AbstractLayer}
    loss::AbstractLoss

    function NeuralNetwork(layers::Vector{AbstractLayer}, loss::AbstractLoss)
        new(layers, loss)
    end
end

function forward(nn::NeuralNetwork, X::Array{Float64, 2}; build_graph::Bool=false)
    build_graph = Val(build_graph)

    for layer in nn.layers
        X = forward(layer, X, build_graph)
    end
    X
end

function backward(nn::NeuralNetwork,Y::Array{Float64}, A::Array{Float64}, lr::Float64=0.01)
    dZ = backward(nn.loss, Y, A)
    dZ*=lr
    for layer in reverse(nn.layers)
        dZ  = backward(layer, dZ)
    end
end
function predict(nn::NeuralNetwork, X::Array{Float64, 2})
    forward(nn, X, build_graph=false)
end

function train(nn::NeuralNetwork, X::Array{Float64, 2},Y::Array{Float64}, iterations::Int, Xt::Array{Float64, 2},Yt::Array{Float64})
    for i in 0:iterations
        A = forward(nn, X, build_graph=true)
        if i%100 == 0
            println("-----------------------")
            At = forward(nn, Xt, build_graph=false)
            acn, acp = accuracy_per_class(Yt, At)
            println("Test ac: neg: $acn | pos: $acp ")

            acn, acp = accuracy_per_class(Y, A)
            println("Train ac: neg: $acn | pos: $acp ")

            loss = forward(nn.loss, Y, A)
            println("Loss $i: $loss")
        end
        backward(nn, Y, A)
    end
end

function accuracy_per_class(Y::Array{Float64}, A::Array{Float64})
    P = round.(A)
    sum((P .== 0) .& (Y .== 0))/sum(Y .== 0), sum((P .== 1) .& (Y .== 1))/sum(Y .== 1)
end

function load_data_cats()
    train_x = h5read("./data/cat_images/train.h5", "train_set_x")
    train_y = h5read("./data/cat_images/train.h5", "train_set_y")
    train_x = permutedims(train_x, [1,3,2,4])/255
    train_x = reshape(train_x, (:, size(train_x)[4]))

    test_x = h5read("./data/cat_images/test.h5", "test_set_x")
    test_y = h5read("./data/cat_images/test.h5", "test_set_y")
    test_x = permutedims(test_x, [1,3,2,4])/255
    test_x = reshape(test_x, (:, size(test_x)[4]))

    return train_x, test_x, train_y, test_y
end

function load_data_wine_quality()
    CSV.read("./data/wine_quality/winequality-red.csv")
end

# show_image(x::Array{Float64,1}) = colorview(RGB, reshape(x, (3, 64, 64)))


x,xt,y,yt = load_data_cats()
nn = NeuralNetwork([
    LinearLayer(12288, 200),
    ReLULayer(),
    LinearLayer(200, 100),
    ReLULayer(),
    LinearLayer(100, 50),
    ReLULayer(),
    LinearLayer(50, 25),
    ReLULayer(),
    LinearLayer(25, 1),
    SigmoidLayer()
], BinaryCrossentropyLoss())
Y = reshape(Array{Float64}(y), (1, :))
Yt = reshape(Array{Float64}(yt), (1, :))

# using Debugger
# using Profile
# using Juno
train(nn, x, Y, 1000, xt, Yt)
# Profile.clear()
# @profiler
@btime train(nn, x, Y, 100, xt, Yt)
using CSV
