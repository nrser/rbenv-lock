# frozen_string_literal: true

# Requirements
# =======================================================================

# Project / Package
# -----------------------------------------------------------------------
require_relative './base'


# Definitions
# =======================================================================

# Execute in a lock's environment.
# 
class RbenvLock::Cmd::Exec < RbenvLock::Cmd::Base
  NAME = 'exec'
  
  ALIASES = ['in']
  
  DESCRIPTION = "Execute a command in a lock's environment"
  
  USAGE = "rbenv lock exec BIN -- COMMAND..."
  
  def on_run
    debug "Entering {#{ self.class.name }##{ __method__ }}...",
      argv: argv,
      args: args,
      options: options
    
    bin = args[0]
    cmd = args[1..-1]
    lock = RbenvLock::Lock.read bin
    
    if lock.nil?
      err "ERROR Lock not found: #{ bin.inspect }"
      err
      err "Use `rbenv lock list` to view available locks."
      err
      exit 1
    end
    
    lock.exec cmd.shelljoin, unsetenv_others: false
  end
  
end # class RbenvLock::Cmd::List
