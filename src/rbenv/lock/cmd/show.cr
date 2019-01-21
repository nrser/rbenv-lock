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
class Show < Base
  @@aliases = [ "status", "dump" ]
  
  @@description = %{See what's going on with a lock.}
  
  @@usage = "rbenv lock status NAME"
  
  @@examples = [
    {
      name: %{1. Basic usage},
      body: \
        %{    rbenv lock status qb\n} \
        %{\n}
    },
  ]
  
  
  def on_run
    name = args[0]
    
    exe = Rbenv::Lock::Exe.load name
    
    if exe.nil?
      raise Error::User::Argument.new \
        "Lock executable #{ name.inspect } not found."
    end
    
    # exe.status
    
    ExitStatus::OK
  end
  
end # class Show


# /Namespace
# =======================================================================

end # module Cmd
end # module Lock
end # module Rbenv
