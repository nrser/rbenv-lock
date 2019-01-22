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
class RbenvLock::Cmd::Remove < RbenvLock::Cmd::Base
  NAME = 'remove'
  
  ALIASES = ['rm']
  
  DESCRIPTION = "Remove a lock"
  
  USAGE = "rbenv lock #{ NAME } BIN [OPTIONS]"
  
  OPTIONS = {
    gemset: [
      '-s', '--gemset',
      "Remove gemset too.",
    ],
    
    gem: [
      '-g', '--gem',
      "Uninstall gem as well.",
    ],
  }
  
  def on_run
    debug "Entering {#{ self.class.name }##{ __method__ }}...",
      argv: argv,
      args: args,
      options: options
    
    bin = args[0]
    lock = RbenvLock::Lock.read bin
    
    if lock.nil?
      err "ERROR Lock not found: #{ bin.inspect }"
      err
      err "Use `rbenv lock list` to view available locks."
      err
      exit 1
    end
    
    lock.remove options
  end
  
end # class RbenvLock::Cmd::Remove
