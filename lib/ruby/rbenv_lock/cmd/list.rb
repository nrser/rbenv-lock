# frozen_string_literal: true

# Requirements
# =======================================================================

# Project / Package
# -----------------------------------------------------------------------
require_relative './base'


# Definitions
# =======================================================================

# List locks.
# 
# @example 1.  Basic usage
#       rbenv lock list
#   
#   Output looks like `<BIN>: <VERSION>`.
# 
# @example 2.  List details
#       rbenv lock list --long
#   
#   Lock details are written in YAML format.
# 
class RbenvLock::Cmd::List < RbenvLock::Cmd::Base
  NAME = 'list'
  
  ALIASES = ['ls']
  
  DESCRIPTION = "List locks."
  
  USAGE = "rbenv lock list [OPTIONS]"
  
  OPTIONS = {
    long: [
      '-l', '--long',
      "Print lock details (YAML format)"
    ],
  }
  
  def on_run
    debug "RUNNING `list` command...", argv: argv
    
    locks = RbenvLock::Lock.list
    
    if options[:long]
      require 'yaml'
      
      data = locks.map { |lock|
        {
          'bin'     => lock.bin,
          'ruby'    => lock.ruby_version,
          'gem'     => lock.gem_name,
          'gemset'  => lock.gemset,
          'path'    => lock.path,
          'target'  => lock.target,
        }.reject { |k, v| v.nil? }
      }
      
      out YAML.dump( data )
      
    else
      
      locks.each { |lock| out "#{ lock.bin }: #{ lock.ruby_version }" }
    end
  end
  
end # class RbenvLock::Cmd::List
