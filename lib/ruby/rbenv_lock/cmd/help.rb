# frozen_string_literal: true

# Requirements
# =======================================================================

# Project / Package
# -----------------------------------------------------------------------
require_relative './base'


# Definitions
# =======================================================================

# Help locks.
# 
class RbenvLock::Cmd::Help < RbenvLock::Cmd::Base
  NAME = 'help'
  
  ALIASES = ['-h', '--help']
  
  DESCRIPTION = \
    "Get help on `rbenv lock` in general or about a specific command."
  
  USAGE = "rbenv lock help [COMMAND]"
  
  
  def general
    locks_dir = RbenvLock::Env.locks_dir
    
    err <<-END
Mange "locks" - small executable scripts (like shims) placed in

    #{ locks_dir }/<BIN>

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
  
    RbenvLock::Cmd.each do |cmd|
      err "  #{ cmd::USAGE }"
      err "    #{ cmd::DESCRIPTION }"
      err
    end
  end
  
  
  def on_run
    if args.empty?
      general
      exit 1
    end
    
    cmd_class = RbenvLock::Cmd.each { |cmd_class|
      if cmd_class.names.include? args[0]
        cmd_class.new( ['--help'] ).run!
        exit 0
      end
    }
    
    fatal "Unknown arguments: #{ args.inspect }", help: parser.to_s
  end
  
end # class RbenvLock::Cmd::Help
