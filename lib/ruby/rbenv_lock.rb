require 'pathname'
require 'shellwords'
require 'fileutils'

require_relative './rbenv_lock/output'
require_relative './rbenv_lock/env'
require_relative './rbenv_lock/lock'
require_relative './rbenv_lock/cmd'

class Object
  def quote
    to_s.shellescape
  end
end

module RbenvLock
  
  # Constants
  # ============================================================================
  
  
  
  # Mixins
  # ============================================================================
  
  include RbenvLock::Output
  
  
  # Module Methods
  # ============================================================================
  
  def self.locks_dir
    @locks_dir ||= Pathname.new(
      Env[:locks_dir] ||
      File.join( rbenv_root, 'locks' )
    ).expand_path
  end
  
  
  def self.rbenv_root
    @rbenv_root ||= ENV['RBENV_ROOT'] || `rbenv-root`.chomp
  end
  
  
  def self.rbenv_versions
    @rbenv_versions ||= `rbenv-versions --bare 2>/dev/null`.
      lines.
      map( &:chomp )
  end
  
  
  def self.rbenv_current
    @rbenv_current ||= `rbenv-version-name`.chomp
  end
  
  
  def self.rbenv_global
    @rbenv_global ||= `rbenv-global`.chomp
  end
  
  
  def self.shim_dir
    @shim_dir ||= File.join rbenv_root, 'shims'
  end
  
  
  def self.shim_for bin
    File.join shim_dir, bin
  end
  
  
  def self.rbenv_version_for input
    # Exact match, just return it
    return input if rbenv_versions.include? input
    
    # Alias for the current version
    return rbenv_current if input == 'current'
    
    # Alias for the global version
    return rbenv_global if input == 'global'
    
    # If we prefix match a *single* version, use that
    matches = rbenv_versions.select { |version| version.start_with? input }
    return matches[0] if matches.length == 1
    
    # We got nada
    err "ERROR Can't find Ruby version #{ input.inspect }"
    err
    err "Available versions:"
    err
    rbenv_versions.each { |version| err "- #{ version }" }
    err
    err "Available aliases:"
    err
    err "  current -> #{ rbenv_current }"
    err "  global  -> #{ rbenv_global }"
    err
    exit 1
  end
  
  
  def self.rbenv_prefix version
    @rbenv_prefixes ||= {}
    @rbenv_prefixes[version] ||= `rbenv-prefix #{ version.shellescape }`.chomp
  end
  
  
  def self.add_common_options parser

  end
  
  

  
  
  # Sub-Commands
  # ----------------------------------------------------------------------------
  
  def self.help_cmd
    puts "HELP!"
  end
  
  
  def self.run cmd, *argv
    debug "Starting run...", cmd: cmd, argv: argv
    
    case cmd
    when 'help', '-h', '--help'
      help_cmd argv
      
    when 'list', 'ls'
      RbenvLock::Cmd::List.new( argv ).run!
      
    when 'create'
      RbenvLock::Cmd::Create.new( argv ).run!
      
    when 'remove', 'rm'
      raise "TODO"
      
    else
      fatal "Bad command: #{ cmd.inspect }"
    end
  end
  
end
