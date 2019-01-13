require 'pathname'
require 'shellwords'
require 'fileutils'

# I guess some old Rubies need this
require 'rubygems'

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
  # ========================================================================

  ROOT = Pathname.new( __dir__ ).join( '..', '..' ).expand_path


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
    @rbenv_root ||= \
      ENV['RBENV_ROOT'] || `rbenv-root 2>/dev/null || rbenv root`.chomp
  end
  
  
  def self.rbenv_versions
    @rbenv_versions ||= \
      `rbenv-versions --bare 2>/dev/null || rbenv versions --bare`.
        lines.
        map( &:chomp )
  end
  
  
  # Map of RBEnv's Ruby versions (which are {String}s) to a {Gem::Version}
  # instance of them, taking account of the `-pXXX` format for `2.0.0` versions.
  # 
  # Used for resolving requirement strings like '~> 2.3.7' to an appropriate
  # installed version (see {.rbenv_version_for}).
  # 
  # @return [Hash<String, Gem::Version>]
  # 
  def self.rbenv_version_objects
    @rbenv_version_objects ||= \
      rbenv_versions.
        map { |string|
          [ string, Gem::Version.new( string.gsub( /\-p(\d+)/, '.\1' ) ) ]
        }.
        to_h
  end # #rbenv_version_objects
  
  
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
  
  
  # Find the latest Ruby version installed with RBEnv that satisfies 
  # `requirements`.
  # 
  # @param [Array<Object>] requirements
  #   Probably {String}s in our case, but really can be anything that 
  #   {Gem::Requirement.new} accepts.
  # 
  # @return [String]
  #   The latest RBEnv Ruby version that satisfies.
  # 
  # @raise [ArgumentError]
  #   If no `requirements` are provided.
  # 
  # @raise [Gem::Requirement::BadRequirementError]
  #   If any of `requirements` are ill-formed. See {Gem::Requirement.new}.
  # 
  # @raise [RuntimeError]
  #   If none of the rbenv versions satisfy the `requirements`.
  # 
  def self.rbenv_version_for *requirements
    # Check we received *something*, otherwise a {Gem::Requirement} will be
    # constructed that accepts anything, which doesn't make sense for locks
    if requirements.empty?
      raise ArgumentError, "Must provide at least one `requirement`"
    end
    
    # Take care of special cases
    if  requirements.length == 1 &&
        requirements[ 0 ].is_a?( String )
      
      # Exact match, just return it. We really no longer *need* this, 'cause
      # the {Gem::Requirement} matching will take care of it, but the code was
      # already here and it is simpler and faster in this case.
      return requirements[ 0 ] if rbenv_versions.include? requirements[ 0 ]
      
      # Alias for the current version
      return rbenv_current if requirements[ 0 ] == 'current'
      
      # Alias for the global version
      return rbenv_global if requirements[ 0 ] == 'global'
      
    end # if special cases
    
    # This will raise if any of `requirements` are ill-formed, which I want to
    # handle in calling code for the CLI use-case (though I may not be at the
    # moment)
    req = Gem::Requirement.new *requirements
    
    satisfying_versions = \
      rbenv_version_objects.
        select { |string, version| req.satisfied_by? version }.
        to_h
    
    # Throw up if nothing satisfied
    if satisfying_versions.empty?
      raise RuntimeError, (
        "None of rubies #{ rbenv_versions.join ', ' } " +
        "satisfy #{ requirements.map( &:to_s ).join ', ' }"
      )
    end
    
    # Get the most recent that satisfied
    satisfying_versions.max_by { |string, version| version }[ 0 ]
        
    # # If we prefix match a *single* version, use that
    # matches = rbenv_versions.select { |version| version.start_with? input }
    # return matches[0] if matches.length == 1
    
    # # We got nada
    # err "ERROR Can't find Ruby version #{ input.inspect }"
    # err
    # err "Available versions:"
    # err
    # rbenv_versions.each { |version| err "- #{ version }" }
    # err
    # err "Available aliases:"
    # err
    # err "  current -> #{ rbenv_current }"
    # err "  global  -> #{ rbenv_global }"
    # err
    # exit 1
  end # .rbenv_version_for
  
  
  def self.rbenv_prefix version
    @rbenv_prefixes ||= {}
    @rbenv_prefixes[version] ||= \
      `rbenv-prefix #{ version.quote } 2>/dev/null || rbenv prefix #{ version.quote }`.chomp
  end
  
  
  # Sub-Commands
  # ----------------------------------------------------------------------------
  
  def self.help_cmd
    puts "HELP!"
  end
  
  
  def self.run cmd, *argv
    debug "Starting run...", cmd: cmd, argv: argv
    
    RbenvLock::Cmd.all.each do |cmd_class|
      debug "Switching command...",
        cmd_class: cmd_class,
        names: cmd_class.names,
        cmd: cmd
      
      if cmd_class.names.include? cmd
        return cmd_class.new( argv ).run!
      end
    end
    
    fatal "Bad command: #{ cmd.inspect }"
    
  end
  
end # module RbenvLock
