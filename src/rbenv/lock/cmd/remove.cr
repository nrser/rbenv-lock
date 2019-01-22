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

# Remove locks.
# 
class Remove < Base
  @@aliases = [ "rm", "delete" ]
  
  @@description = %{Remove a lock and/or its gem and gemset.}
  
  @@usage = "rbenv lock remove NAME [OPTIONS]"
  
  getter? path : Bool = true
  getter? gem : Bool = false
  getter? gemset : Bool = false
  getter? all : Bool = false
  
  
  protected def init_options( parser ) : Nil
    
    parser.on(
      "--no-path",
      %{Don't remove the lock executable file.\n} \
      %{ \n} \
      %{Defaults to `true`.}
    ) { @path = false }
    
    parser.on(
      "-s", "--gemset",
      %{Remove gemset too.}
    ) { @gemset = true }
    
    parser.on(
      "-g", "--gem",
      %{Remove gem as well.}
    ) { @gem = true }
    
    parser.on(
      "-a", "--all",
      %{Remove whatever is there.}
    ) { @all = true }
    
  end # init_options
  
  
  def on_run
    name = args[0]
    exe = Rbenv::Lock::Exe.load! name
    
    if all?
      exe.remove
    else
      exe.remove path: path?, gem: gem?, gemset: gemset?
    end
    
    ExitStatus::OK
  end
  
end # class Remove


# /Namespace
# =======================================================================

end # module Cmd
end # module Lock
end # module Rbenv
