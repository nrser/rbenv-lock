# Requirements
# =======================================================================

# Project / Package
# -----------------------------------------------------------------------
require "./base"
require "../exe"


# Namespace
# =======================================================================

module Rbenv
module Lock
module Cmd

# Definitions
# =======================================================================

# Help locks.
# 
class Help < Base
  
  @@aliases = [ "-h", "--help" ]
  
  @@description = \
    "Get help on `rbenv lock` in general or about a specific command."
  
  @@usage = "rbenv lock help [COMMAND]"
  
  
  def general
    out! <<-END
Mange "locks" - small executable scripts (like shims) placed in

    #{ Rbenv::Lock::Exe.dir }/<BIN>

that *always* run BIN using a specific Ruby version, with optional gemset[1]
for full isolation.

  [1] Gemsets require `rbenv-gemset` plugin, available separately.
      See https://github.com/jf/rbenv-gemset for details.

When the locks directory precedes the `rbenv` shims directory in the system
PATH the lock script will be run instead of the shim, causing the target
to run using that Ruby version regardless of what Ruby version is active
with `rbenv`.

Commands:
END
  
    Cmd.all.each do |cmd_class|
      out! "  #{ cmd_class.usage }"
      out! "    #{ cmd_class.description }"
      out!
    end
  end
  
  
  def on_run : ExitStatus
    args = @args
    
    if args.empty?
      general
      return ExitStatus::FAIL
    end
    
    Cmd.find!( args[ 0 ] ).new( [ "--help" ] ).run!
  end
  
end # class Help



# /Namespace
# =======================================================================

end # module Cmd
end # module Lock
end # module Rbenv
