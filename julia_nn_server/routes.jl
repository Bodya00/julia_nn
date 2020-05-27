using Genie.Router
using DataloadController
using NeuralNetworkController

route("/") do
  serve_static_file("welcome.html")
end
route("/file_view", DataloadController.file_view, named=:fileview)
route("/data_load", DataloadController.choose_file, named=:dataload)
route("/data_load", DataloadController.read_file, method=POST)
route("/configure_nn", NeuralNetworkController.configure_nn)
route("/configure_nn", NeuralNetworkController.start_training, method=POST)
route("/training", NeuralNetworkController.loader_screen, named=:training)
route("/check_prediction_progress", NeuralNetworkController.check_prediction_progress)
