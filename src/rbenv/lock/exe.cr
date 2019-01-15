# Requirements
# =======================================================================

require "yaml"


# Namespace
# =======================================================================

module Rbenv
module Lock


# Definitions
# =======================================================================

# Runtime representation of a lock executable. Includes methods to write 
# lock files, read them back in, and `exec` in their environment.
# 
# Lock executables live in {.dir}, and are simply executable YAML files whose
# "shebang" lines point to `//bin/rbenv-lock-exec-file`. Hence the executables
# serve as the database as well, each containing all the data for a particular
# lock.
# 
class Exe
  
  # Mixins
  # ==========================================================================
  
  # Add logging support
  include NRSER::Log
  
  
  # Singleton Methods
  # ==========================================================================
  
  # Where to put lock executables if nothing is specified in the environment
  # (see {Env}):.
  # 
  # Equivalent to `"$(rbenv root)/locks".
  # 
  def self.default_dir : String
    @@default_locks_dir ||= File.join( Rbenv::Lock.rbenv.root, "locks" )
  end
  
  
  # Absolute path to where the lock executable files go.
  #
  # Looks for `$RBENV_LOCK_LOCKS_DIR` first (via `Env`), falling back to
  # {.default_locks_dir}. Exapnds either of them to form the response.
  #
  def self.dir : String
    File.expand_path( Env[ :locks_dir ] || default_locks_dir )
  end
  
  
  # The absolute path to a executable file given its name (relative to the 
  # current {.dir}).
  # 
  def self.path_for( name ) : String
    File.join self.class.dir, name
  end
  
  
  # Load a lock up from a `YAML` file path.
  # 
  def self.load( path ) : self
    contents = File.read path
    data = YAML.parse( contents ).as_h
    
    env = if data.has_key?( "gem_name" )
      data[ "gem_name" ].as_h.map { |k, v|
        [ k.as_s, v.as_s ]
      }.to_h
    else
      {} of String => String?
    end
    
    new name: File.basename( path ),
        ruby_version: data[ "ruby_version" ].as_s,
        target: data[ "target" ].as_s,
        gemset: data.has_key?( "gemset" ) ? data[ "gemset" ].as_s : nil,
        gem_name: data.has_key?( "gem_name" ) ? data[ "gem_name" ].as_s : nil,
        path: path,
        direct: !!( data.has_key?( "direct" ) ? data[ "direct" ].raw : false ),
        env: env
  end # .load
  
  
  # Get a list of all locks in `.dir`.
  # 
  def self.list : Array(self)
    dir = self.dir
    
    locks = [] of self
    
    # Bail out `.dir` doesn't exist.
    unless File.directory?( dir )
      # TODO warn "Locks directory #{ dir } does not exist!", dir: dir
      return locks
    end
    
    Dir.foreach( dir ) do |filename|
      path = File.join locks_dir, filename
      
      if !filename.start_with?( '.' ) && File.file?( path )
        begin
          locks << read( path )
        rescue error : Exception
          # TODO warn "Failed to load lock bin file",
          #   path: path
        end
      end
    end
    
    locks
  end # .list
  
  
  # Instance Variables
  # ==========================================================================
  
  @direct : Bool
  @env : Hash(String, String?)
  @gem_name : String?
  @gem_version : String?
  @gemset : String?
  @name : String
  @path : String?
  @ruby_version : String
  @target : String
  @target_path : String?
  
  
  # Properties
  # ==========================================================================
  
  getter gem_name : String?
  getter gem_version : String?
  getter gemset : String?
  getter name : String
  getter ruby_version : String
  getter target : String
  
  
  # Construction
  # ==========================================================================
  
  def initialize( @name,
                  @ruby_version,
                  @target,
                  @direct = false,
                  env : Process::Env = nil,
                  @gemset = nil,
                  @gem_name = nil,
                  @gem_version = nil,
                  path = nil, )
    
    # `@target_path` may require shell-outs, so leave it `nil` until needed
    # (`#target_path` resolves it dynamically)
    @target_path = nil
    
    @path = if path.nil?
      nil
    else
      File.expand_path path
    end
    
    @env = {} of String => String?
    @env.merge!( env ) unless env.nil?
  end
  
  
  # Instance Methods
  # ==========================================================================
  
  # Absolute path to the lock file.
  # 
  def path : String
    @path ||= self.class.path_for name
  end
  
  
  # Does this lock go directly to the executable in `rbenv prefix $VERSION`
  # (or does it route through the shim)?
  # 
  def direct?
    @direct
  end
  
  
  # Does this lock use a gemset (required `rbenv-gemset` plugin)?
  # 
  def gemset?
    !@gemset.nil?
  end
  
  
  def version_bin_dir
    File.join( Lock.rbenv.prefix( ruby_version ), "bin" )
  end
  
  
  def direct_version_bin_path_for( bin )
    File.join version_bin_dir, bin
  end
  
  
  def gemset_root : String?
    File.join? \
      Lock.rbenv.prefix( ruby_version ),
      "gemsets",
      gemset
  end
  
  
  def gemset_bin_dir : String?
    File.join? gemset_root, "bin"
  end
  
  
  def direct_gemset_bin_path_for( name ) : String?
    File.join? gemset_bin_dir, name
  end
  
  
  # Find the path to a bin file.
  # 
  # NOTE
  # 
  # This method was essentailly coppied over from the Ruby version, and I'm not
  # entirely sure why it was written like this... it seems to try to form the
  # path *without* actually seeing where files are and aren't... but besides
  # the time cost, there doesn't appear to be any other reason for that..?
  # 
  def which( bin : String ) : String
    # Not direct, go to the shim
    return Lock.rbenv.shim_path( bin ) unless direct?
    
    # We're going to direct to the executable, so need to figure out if has a
    # gemset
    if (direct_gemset_bin_path = direct_gemset_bin_path_for( bin ))
      
      if bin == name
        # The lock bin will def be in the gemset
        direct_gemset_bin_path
        
      elsif {"gem", "ruby"}.includes?( bin )
        # These should always be in Ruby version (they come with it)
        direct_version_bin_path_for bin
        
      elsif File.exists?( direct_gemset_bin_path )
        # Ok, had to check... it is in the gemset
        direct_gemset_bin_path
      
      else
        # It's gotta be in the Ruby version
        direct_version_bin_path_for bin
      end
    else
      # The lock is not in a gemset, so the bin needs to be in the version's
      # bin dir
      direct_version_bin_path_for bin
    end
  end # #which
  
  
  def target_path
    @target_path ||= which target
  end
  
  
  def env : Hash(String, String?)
    @env.dup.tap do |env|
      if env.has_key? "RBENV_VERSION"
        warn "Don't define RBENV_VERSION in lock env, it gets clobbered by `Rbenv::Lock::Exe#ruby_version`"
      end
    
      env[ "RBENV_VERSION" ] = ruby_version
    end
  end
  
  
  def exec( command : String, args : Array(String) )
    Process.exec command: command, args: args, shell: true, env: env
  end
  
  
  def exec( command : String, *args : String )
    exec command: command, args: args
  end
  
  
  def exec_target( args : Array(String) )
    exec command: target_path, args: args
  end
  
 
  def exec_target( *args : String )
    exec_target args
  end
  
end # class Exe


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
