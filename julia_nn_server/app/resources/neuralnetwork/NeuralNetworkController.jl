module NeuralNetworkController

using Genie
using Genie.Renderer.Html: html
using Genie.Renderer: redirect
using Genie.Requests: postpayload, rawpayload, jsonpayload, payload, request
using Genie.Responses: setstatus

include("../utils.jl")

function configure_nn()
  html(:neuralnetwork, :configurator)
end

function get!(dict::Dict, key::Any, default::Any=nothing)
    value = get(dict, key, default)
    delete!(dict, key)
    value
end
function form_layer_specific(layer_type, form_data, layer_nb)
    Dict(
    "linear"=>Dict("neuron_count"=> get(form_data, Symbol("neuron_count_$(layer_nb)"), nothing)),
    "sigmoid"=>Dict(),
    "relu"=>Dict()
    )[layer_type]
end

function start_training()
    form_data = postpayload()
    println(form_data)
    lr = parse(Float64, form_data[:lr])
    loss = form_data[:loss]
    batch_size = parse(Int64, form_data[:batch_size])
    iterations = parse(Int64, form_data[:iterations])

    layers = []
    for layer in filter(key->occursin(r"^layer_\d+$", string(key)), keys(form_data))
        layer_num = match(r"^layer_(\d+)$", string(layer))[1]
        layer_type = form_data[layer]
        layer = merge(Dict("layer_type"=>layer_type), form_layer_specific(layer_type, form_data, layer_num))
        push!(layers, layer)
    end
    println(layers)
    println("Started training")
    html(:neuralnetwork, :loader)
end


function check_prediction_progress()
    req = request()
    csv_hash = get_from_cookies(req, "csv_hash")
    println(readdir("user_files/done/"))
    println(csv_hash)
    if !isfile("user_files/done/$(csv_hash)")
        setstatus(425)
    end
end

end
