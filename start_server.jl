using Pkg
Pkg.activate("./julia_nn_server")
using Genie: loadapp, up
loadapp("./julia_nn_server")
up()
