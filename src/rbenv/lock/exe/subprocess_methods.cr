##############################################################################
# `Rbenv::Lock::Exe` Subprocess Methods
# ============================================================================
# 
# The `//src/rbenv/lock/exe.cr` file got a bit big and unwieldy by my standards,
# so I started to split it up. It is `require`d in the main `Exe` file and
# should **NOT** be loaded independently.
# 
# This file contains methods for executing sub-processes in the lock's 
# environment.
# 
##############################################################################

# Requirements
# ============================================================================

### Deps ###

require "nrser/process"


# Namespace
# =======================================================================

module Rbenv
module Lock


# Definitions
# =======================================================================

class Exe
  
  # This method does essentially the same thing as Ruby's `Open3.capture3`,
  # returning a triple of the standard output `String`, standard error `String`,
  # and the exiting `Process::Status`.
  #
  # NOTE This method **blocks** until the `Process` completes.
  #
  def capture(
    command,
    args,
    shell = true,
    env : Hash(String, String?) = {} of String => String?,
    direct = false,
  ) : NRSER::Process::Capture
    merged_env = self.env( direct: direct ).merge_and_delete_nils!( env )
  
    debug "Capturing...",
      command: command,
      args: args,
      shell: shell,
      direct: direct,
      env: {
        arg: env,
        merged: self.class.filter_env( merged_env ),
      }
  
    NRSER::Process.capture \
      command: command,
      args: args,
      shell: shell,
      env: merged_env,
      clear_env: true
  end # #capture
  
  
  # "Streams" a sub-`Process` executed in the `Exe`'s `#env` through the current
  # process' standard IO via assigning `Process::Redirect::Inherit` to `input`,
  # `output` and `error` in `Process.run`, returning the sub-process' exiting
  # `Process::Status`.
  #
  # NOTE This method **blocks** until the `Process` completes, via
  # `Process.run`.
  #
  def stream(
    command,
    args,
    shell = true,
    env : Hash(String, String?) = {} of String => String?,
    direct = false,
  ) : Process::Status
    merged_env = self.env( direct: direct ).merge_and_delete_nils!( env )
  
    debug "Streaming...",
      command: command,
      args: args,
      shell: shell,
      direct: direct,
      env: {
        arg: env,
        merged: self.class.filter_env( merged_env ),
      }
  
    Process.run \
      command: command,
      args: args,
      shell: shell,
      env: merged_env,
      clear_env: true,
      input: Process::Redirect::Inherit,
      output: Process::Redirect::Inherit,
      error: Process::Redirect::Inherit
  end # #stream
  
  
  # Accept splat *args* and pass to the `Array` version.
  # 
  def stream( command : String, *args : String )
    stream command, args
  end
  
  
  # Accept splat *args* and **kwds** and pass to the `Array` version.
  # 
  # EXAMPLE Adding a *direct* named parameter after the *args* splat
  # 
  #     stream gem_exe_path, "specification", "--local", "qb", direct: true
  # 
  def stream( command : String, *args : String, **kwds )
    stream command, args, **kwds
  end
  
  
  # Swap the process out for a command run in the `#env` via `Process.exec`.
  # 
  def exec( command : String, args : Array(String) )
    env = self.env
    
    debug "Exec'ing command...",
      command: command,
      args: args,
      env: self.class.filter_env( env )
    
    Process.exec \
      command: command,
      args: args,
      shell: true,
      env: env,
      clear_env: true
  end
  
  
  # Accept splat *args* and pass to the `Array` version.
  # 
  def exec( command : String, *args : String )
    exec command, args
  end
  
  
  # Swap the process out for the `#target_path` executable.
  # 
  def exec_target( args : Array(String) )
    exec command: target_path, args: args
  end
  
  
  # Accept splat *args* and pass to the `Array` version.
  # 
  def exec_target( *args : String )
    exec_target args
  end
  
end # class Exe


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
