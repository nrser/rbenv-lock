# Requirements
# ============================================================================

### Project / Package ###

require "./base"
require "../exe"


# Namespace
# =======================================================================

module Rbenv
module Lock
module Cmd

# Definitions
# =======================================================================

# Exec locks.
# 
class Exec < Base
  @@aliases = [ "in" ]
  
  @@description = %{Execute a command in a lock's environment.}
  
  @@usage = "rbenv lock exec NAME -- COMMAND..."
  
  @@examples = [
    {
      name: %{1. Show the Gem environemnt for a lock},
      body: \
        %{    rbenv lock exec qb -- gem env\n} \
        %{\n}
    },
  ]
  
  
  def on_run
    name = args[0]
    
    exec_command = double_dash_args[ 0 ]
    exec_args = if double_dash_args.size > 1
      double_dash_args[ 1..-1 ]
    else
      [] of String
    end
    
    exe = Rbenv::Lock::Exe.load! name
    
    exe.exec exec_command, exec_args
  end
  
end # class Exec


# /Namespace
# =======================================================================

end # module Cmd
end # module Lock
end # module Rbenv
