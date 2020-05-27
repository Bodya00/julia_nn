module JuliaNnServer

using Logging, LoggingExtras

function main()
  Base.eval(Main, :(const UserApp = JuliaNnServer))

  include(joinpath("..", "genie.jl"))

  Base.eval(Main, :(const Genie = JuliaNnServer.Genie))
  Base.eval(Main, :(using Genie))
end; main()

end
