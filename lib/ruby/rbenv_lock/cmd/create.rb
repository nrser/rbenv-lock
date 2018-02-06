# frozen_string_literal: true

# Requirements
# =======================================================================

# Project / Package
# -----------------------------------------------------------------------
require_relative './base'


# Definitions
# =======================================================================

# Create a lock (or overwrite one with `--force`)
# 
# @example 1.  Basic usage
#   Lock the `qb` bin to Ruby 2.3.6
#   
#       rbenv lock 2.3.6 qb
#   
# @example 2.  "Full" example
#   Isolate the `qb` bin from the gem of the same name in a gemset (also of
#   the same name).
#   
#   Requires the `rbenv-gemset` plugin.
#   
#   Gemset will be created if it doesn't exist, and gem will be installed in
#   if it isn't present.
#   
#       rbenv lock 2.3.6 qb --gem=qb --gemset=qb
#   
# @example 3.  "Full" example with inferred gem and gemset names
#   Since often times the gem and executable names are the same and that name
#   is a natural choice for an isolating gemset name the `gem` and `gemset`
#   values can be inferred:
#   
#       rbenv lock 2.3.6 qb --gem --gemset
#   
#   Exactly the same result as example (2).
# 
class RbenvLock::Cmd::Create < RbenvLock::Cmd::Base
  NAME = 'create'
  
  DESCRIPTION = "Create a lock (or overwrite one with `--force`)"
  
  USAGE = "rbenv lock create VERSION BIN [OPTIONS]"
  
  DEFAULTS = {
    force: false,
    bin_only: false,
  }
  
  OPTIONS = {
    gemset: [
      '-s', '--gemset[=GEMSET]',
      "Use an gemset via the `rbenv-gemset` plugin (must be installed).",
      " ",
      "Allows isolation of the locked bin's gem and it's dependencies.",
      " ",
      "If the gemset doesn't exist it will be created. If GEMSET is omitted",
      "(just `--gem` is provided) BIN is used as the name.",
      ->( gemset ) { gemset || true }
    ],
    
    gem: [
      '-g', '--gem=[NAME[@VERSION]]',
      "Associate lock with a gem.",
      " ",
      "When provided, the gem will be installed if it's not present",
      "(unless the `--bin-only` option is provided as well).",
      " ",
      "A gem version may added like `--gem=qb@0.3.0` to install a specific",
      "gem version, otherwise it just uses `gem install NAME`.",
      " ",
      "If NAME is omitted, the gem name is assumed to be the same as the BIN.",
      " ",
      "You can use something like `--gem=@0.3.0` to provide a gem version",
      "and assume the gem name is BIN.",
      ->( gem ) { gem || true }
    ],
    
    bin_only: [
      "--bin-only",
      "Just write the lock bin file, don't create gemsets, install gems, etc.",
    ],
    
    force: [
      "-f", "--force",
      "Overwrite lock file if exists",
    ]
  }
  
  
  def on_run
    if args.length < 2
      fatal "Too few arguments", help: parser.to_s
    elsif args.length > 2
      fatal "Too many arguments", help: parser.to_s
    end
    
    version = RbenvLock.rbenv_version_for args[0]
    bin = args[1]
    
    # Use the bin name for the gemset if one wasn't provided
    options[:gemset] = bin if options[:gemset] == true
    
    debug "Running `create` cmd, parsed args:",
      version: version,
      bin: bin,
      options: options
      
    # Parse gem option if present
    if options[:gem]
      if options[:gem] == true
        # If just a bare `-g` or `--gem` was provided, assume the gem has
        # the same name as the bin
        gem_name = bin
        
      elsif options[:gem].start_with? '@'
        # If it's something like `--gem=@0.1.0` then we assume the name to
        # be
        
      elsif options[:gem].include? '@'
        split = options[:gem].split '@', 2
        gem_name = split[0]
        gem_version = split[1]
      else
        gem_name = options[:gem]
        gem_version = nil
      end
    else
      gem_name = nil
      gem_version = nil
    end
    
    lock = RbenvLock::Lock.new \
      bin,
      version,
      gemset: options[:gemset],
      gem_name: gem_name,
      gem_version: gem_version
    
    lock.create force: options[:force], bin_only: options[:bin_only]
  end
  
end # class RbenvLock::Cmd::Create
