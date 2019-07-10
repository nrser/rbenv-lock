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

# Update locks.
# 
class Update < Base
  # @@aliases = [ "up" ]
  
  @@description = %{Update a lock and/or its gem and gemset.}
  
  @@usage = "rbenv lock update NAME [OPTIONS]"
  
  getter ruby_version : Nil | String = nil
  
  protected def init_options( parser ) : Nil
    
    parser.on(
      "-r RUBY_VERSION", "--ruby=RUBY_VERSION",
      %{Change Ruby version (removes and recreates)},
    ) { |ruby_version| @ruby_version = ruby_version }
    
    # parser.on(
    #   "-n NAME", "--name=NAME",
    #   %{Change the name of the lock.\n}
    # ) { |gemset| @gemset = gemset }
    
    # parser.on(
    #   "-s GEMSET", "--gemset=GEMSET",
    #   %{Add or rename a gemset for the lock.\n}
    # ) { |gemset| @gemset = gemset }
    
    # parser.on(
    #   "-g NAME@VERSION", "--gem=NAME@VERSION",
    #   %{Associate lock with a gem.\n}
    # ) { |gem| @gem = gem }
    
    # parser.on(
    #   "--bin-only",
    #   %{Just write the lock bin file, don't create gemsets, install gems, etc.}
    # ) { @bin_only = true }
    
  end # init_options
  
  
  def on_run
    name = args[0]
    exe = Rbenv::Lock::Exe.load! name
    
    if (ruby_version = self.ruby_version)
      exe.update_ruby_version ruby_version
    end
    
    ExitStatus::OK
  end
  
end # class Update


# /Namespace
# =======================================================================

end # module Cmd
end # module Lock
end # module Rbenv
