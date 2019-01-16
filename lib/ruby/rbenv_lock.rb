require 'pathname'
require 'shellwords'
require 'fileutils'

# I guess some old Rubies need this
require 'rubygems'

require_relative './rbenv_lock/rbenv'
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
  
  # Where to read and write locks if nothing is set in the {Env}:
  # `$(rbenv root)/locks`.
  # 
  # @see .locks_dir
  # 
  # @return [String]
  # 
  def self.default_locks_dir
    @default_locks_dir ||= File.join( rbenv.root, 'locks' )
  end
  
  
  # Absolute path to the directory where the lock executables live.
  # 
  # Looks first for the `:locks_dir` key in {Env}. If that is not found,
  # uses {.default_locks_dir}.
  # 
  # @return [String]
  # 
  def self.locks_dir
    @locks_dir ||= File.expand_path( Env[ :locks_dir ] || default_locks_dir )
  end
  
  
  # Get the {Rbenv} object used to interface with the rbenv CLI, which caches
  # read data since shell-outs are expensive in our book.
  # 
  # @return [Rbenv]
  # 
  def self.rbenv
    @rbenv ||= Rbenv.new
  end
  
  
  # Find the latest Ruby version installed with rbenv that satisfies 
  # `requirements`.
  # 
  # @param [Array<Object>] requirements
  #   Probably {String}s in our case, but really can be anything that 
  #   {Gem::Requirement.new} accepts, plus two special cases that **must**
  #   be the *only* requirement:
  #   
  #   1.  `"current"` - returns the currently active ruby version
  #       (like you get from `rbenv version-name`).
  #       
  #   2.  `"global"` - returns the global ruby version (like you get from 
  #       `rbenv global`).
  # 
  # @return [String]
  #   The latest rbenv Ruby version that satisfies.
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
  def self.ruby_version_for *requirements
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
      return requirements[ 0 ] if rbenv.versions.include? requirements[ 0 ]
      
      # Alias for the current version
      return rbenv.current if requirements[ 0 ] == 'current'
      
      # Alias for the global version
      return rbenv.global if requirements[ 0 ] == 'global'
      
    end # if special cases
    
    # This will raise if any of `requirements` are ill-formed, which I want to
    # handle in calling code for the CLI use-case (though I may not be at the
    # moment)
    req = Gem::Requirement.new *requirements
    
    satisfying_versions = \
      rbenv.version_objects.
        select { |string, version| req.satisfied_by? version }.
        to_h
    
    # Throw up if nothing satisfied
    if satisfying_versions.empty?
      raise RuntimeError, (
        "None of rubies #{ rbenv.versions.join ', ' } " +
        "satisfy #{ requirements.map( &:to_s ).join ', ' }"
      )
    end
    
    # Get the most recent that satisfied
    satisfying_versions.max_by { |string, version| version }[ 0 ]
    
  end # .ruby_version_for
  
  
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
    
  end # .run
  
end # module RbenvLock
