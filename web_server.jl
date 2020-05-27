using Genie, Genie.Router, Genie.Renderer.Html, Genie.Requests
using Genie.Responses: getresponse
using Genie.Cookies: set!
include("utils.jl")

form = """
<form action="/" method="POST" enctype="multipart/form-data">
  <input type="file" name="yourfile" /><br/>
  <input type="submit" value="Submit" />
</form>
"""

route("/") do
  set!(getresponse(), "test", "test_str")
  html(form)
end

route("/", method = POST) do
  session_id = get_from_cookies(request(), "test")
  println(session_id)
  filespayload()
end

up()
