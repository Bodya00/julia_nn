module DataloadController

using Genie
using Genie.Requests: request, filespayload
using Genie.Responses: getresponse
using Genie.Renderer.Html: html
using Genie.Renderer: redirect
using Genie.Cookies: set!

using CSV
using DataFrames
using UUIDs

include("../utils.jl")

function choose_file()
      html(:dataload, :choose_file)
end

function read_file()
      req = request()
      csv_hash = uuid4()
      set!(getresponse(), "csv_hash", csv_hash)
      file = filespayload(:train)
      write(file, filename="user_files/train/$(csv_hash)")
      file = filespayload(:pred)
      write(file, filename="user_files/pred/$(csv_hash)")
      redirect(:fileview)
end

function read_csv(path::String)
      CSV.read(path, header=false, type=Float64, strict=true)
end

function validate_csv_under(path::String)
      return try
            data_file = read_csv(path)
            println(size(data_file))
            size(data_file)[1] < 0 && throw("CSV must have at least 1 row")
            size(data_file)[2] < 2 && throw("CSV must have at least 2 columns")
            disallowmissing!(data_file)
            data_file
      catch e
            println("Error: $(e) on file $(path)")
      end
end

function validate_integrity(train_csv::DataFrame, pred_csv::DataFrame)
      size(train_csv)[2] == size(pred_csv)[2]
end

function file_view()
      req = request()
      csv_hash = get_from_cookies(req, "csv_hash")
      train_path = "user_files/train/$(csv_hash)"
      pred_path = "user_files/pred/$(csv_hash)"
      train_csv = validate_csv_under(train_path)
      pred_csv = validate_csv_under(pred_path)
      is_data_valid = false
      (file_repr_train, file_repr_pred) = if !isnothing(train_csv) && !isnothing(pred_csv) && validate_integrity(train_csv, pred_csv)
            is_data_valid = true
            repr(MIME("text/html"), train_csv), repr(MIME("text/html"), pred_csv)
      else
            "", ""
      end
      html(:dataload, :file_view, file_repr_train=file_repr_train, file_repr_pred=file_repr_pred, is_valid=is_data_valid)
end

end
