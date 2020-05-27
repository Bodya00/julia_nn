using Genie.HTTPUtils
import HTTP


function get_from_cookies(req::HTTP.Request, key::Union{String,Symbol}; encrypted::Bool = true) :: Union{Nothing,String}
  if haskey(HTTPUtils.Dict(req), "cookie") || haskey(HTTPUtils.Dict(req), "Cookie")
      for cookie in split(Dict(request())["cookie"], "; ")
        if startswith(lowercase(cookie), lowercase(string(key)))
          value = split(cookie, '=')[2] |> String
          value = Genie.Encryption.decrypt(value)

          return value
        end
      end
    else
      return nothing
    end
end
