# Requirements
# =======================================================================

require "yaml"
require "file_utils"


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
  
  # Constants
  # ==========================================================================
  
  DIRTY_ENV_NAMES = {
    "GEM_HOME",
    "GEM_PATH",
    "RBENV_DIR",
    "RBENV_HOOK_PATH",
    "RBENV_VERSION",
    
    # Additional places that Ruby will search when `require`ing.
    "RUBYLIB",
  }
  
  
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
    File.expand_path( Env[ :locks_dir ]? || default_dir )
  end
  
  
  def self.exec_file_bin_path : String
    File.join Lock.rbenv.root, "plugins", "bin", "rbenv-lock-exec-file"
  end
  
  
  # The absolute path to a executable file given its name (relative to the 
  # current {.dir}).
  # 
  def self.path_for( name ) : String
    File.join dir, name
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
        ruby_version: Lock.rbenv.version_for( data[ "ruby_version" ].as_s ),
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
    
    Dir.each_child( dir ) do |filename|
      path = File.join dir, filename
      
      if File.file?( path )
        begin
          locks << load( path )
        rescue error : Exception
          warn "Failed to load lock bin file",
            path: path
        end
      end
    end
    
    locks
  end # .list
  
  
  # Instance Variables
  # ==========================================================================
  
  @env : Hash(String, String?)
  @gemdir : String?
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
  property? direct : Bool
  
  
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
  
  
  def create( force : Bool = false, **kwds ) : Nil
    if force || !File.exists?( path )
      write **kwds
    else
      raise Error::User.new \
        "Lock file exists: #{ path }, use --force to overwrite"
    end
  end
  
  
  def to_data
    {
      ruby_version: ruby_version,
      target: target,
      gemset: gemset,
      gem_name: gem_name,
      path: path,
      direct: direct?,
      env: @env.dup,
    }.to_h.compact
  end
  
  
  def gem_exe_path : String
    Lock.rbenv.gem_exe_path( ruby_version )
  end
  
  
  def gem_spec : YAML::Any?
    gem_name = self.gem_name.not_nil!
    
    capture = self.capture \
      command: gem_exe_path,
      args: { "specification", "--local", gem_name }
    
    if capture[ :status ].success?
      YAML.parse capture[ :out ]
    end
  end
  
  
  def ensure_gem : Nil
    gem_spec = self.gem_spec
    gem_version = self.gem_version
    gem_name = self.gem_name.not_nil!
    
    # If the gem is not installed or isn't the right version...
    if  gem_spec.nil? ||
        (gem_version && gem_spec[ :version ].as_s != gem_version)
    
      # We need to install the gem
      command = gem_exe_path
      args = [ "install", gem_name, ]
      
      # Specify the version if we have one
      if gem_version
        args << "--version"
        args << gem_version
      end
      
      info "Installing gem #{ gem_name }...",
        command: command,
        args: args
      
      status = stream \
        command: command,
        args: args
      
      if status.success?
        info "Installed gem #{ gem_name }"
      else
        raise Error::External::Process.new \
          "Failed to install gem #{ gem_name }",
          command: command,
          args: args,
          status: status
      end
    end # if need to install
  end # #ensure_gem
  
  
  def write( bin_only : Bool = false, mode : Int = 0o755 ) : Nil
    unless bin_only
      if (gemset_dir = self.gemset_dir)
        unless File.directory? gemset_dir
          FileUtils.mkdir_p gemset_dir, mode
        end
      end
      
      ensure_gem if gem?
    end
    
    Dir.mkdir_p( self.class.dir ) unless File.directory?( self.class.dir)
    
    File.open path, "w" do |file|
      file.puts "#!/usr/bin/env #{ self.class.exec_file_bin_path }"
      file.puts
      to_data.to_yaml file
    end
    
    File.chmod path, mode
  end
  
  
  # Absolute path to the lock file.
  # 
  def path : String
    @path ||= self.class.path_for name
  end
  
  
  # Does this lock use a gemset (required `rbenv-gemset` plugin)?
  # 
  # NOTE
  #
  # Not all that useful since the type system doesn't let you gaurd on this then
  # work as if `#gemset` is not `nil`, presumably because of concurrency..?
  # 
  def gemset?
    !@gemset.nil?
  end
  
  
  # Do we have a {#gem_name}?
  #
  # NOTE
  #
  # Not all that useful since the type system doesn't let you gaurd on this then
  # work as if `#gem_name` is not `nil`, presumably because of concurrency..?
  #
  def gem?
    !@gem_name.nil?
  end
  
  
  # Absolute path to the `bin` directory in the `Client#prefix` directory for
  # this `Exe`'s `#ruby_version`.
  # 
  def version_bin_dir : String
    File.join( Lock.rbenv.prefix( ruby_version ), "bin" )
  end
  
  
  # Absolute path to a bin file in `#version_bin_dir`.
  # 
  def direct_version_bin_path_for( bin ) : String
    File.join version_bin_dir, bin
  end
  
  
  # Absolute path to the gemset directory (if the `Exe` has a `#gemset`).
  #
  def gemset_dir : String?
    File.join? \
      Lock.rbenv.prefix( ruby_version ),
      "gemsets",
      gemset
  end
  
  
  # Absolute path to the `bin` directory for the `#gemset` (if the `Exe` has a
  # `#gemset`).
  #
  def gemset_bin_dir : String?
    File.join? gemset_dir, "bin"
  end
  
  
  # Absolute path to an executable in the `#gemset_bin_dir` (if the `Exe` has
  # a `#gemset`).
  # 
  def direct_gemset_bin_path_for( name ) : String?
    File.join? gemset_bin_dir, name
  end
  
  
  # Get the absolute path to the `#ruby_version`'s gems directory (where gems
  # are typically installed for that version).
  # 
  def ruby_version_gemdir : String
    @gemdir ||= begin
      clean_env = clean_ENV
      clean_env[ "RBENV_VERSION" ] = ruby_version
      
      # Based off:
      # 
      # https://github.com/crystal-lang/crystal/blob/c9d1eef8fde5c7a03a029d64c8483ed7b4f2fe86/src/process.cr#L550
      # 
      process = Process.new \
        command: Lock.rbenv.gem_exe_path( ruby_version ),
        args: [ "env", "gemdir" ],
        shell: false,
        input: Process::Redirect::Inherit,
        output: Process::Redirect::Pipe,
        error: Process::Redirect::Inherit,
        env: clean_env,
        clear_env: true
        
      output = process.output.gets_to_end
      
      status = process.wait
      $? = status
      
      output.chomp
    end
  end # #gemdir
  
  
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
  
  
  # Get the path for the `#target`, which will be the shim or the actual 
  # script/binary depending on if the instance is `#direct?` or not.
  # 
  def target_path : String
    @target_path ||= which target
  end
  
  
  # Get a copy of `ENV[ "PATH" ]` stripped of all rbenv and rbenv-gemset
  # elements:
  #
  # 1.  `Rbenv::Client#libexec_path` - rbenv's `libexec` directory, which is
  #     where the `rbenv`, `rbenv-exec`, etc. scripts live.
  #
  #     On my Mac with Homebrew installation it is:
  #
  #         /usr/local/Cellar/rbenv/1.1.1/libexec
  #
  #     This is added by the `rbenv` script every time it's run, regardless of
  #     whether it's present or not:
  #
  #     <https://github.com/rbenv/rbenv/blob/59785f6762e9325982584cdab1a4c988ed062020/libexec/rbenv#L73>
  #
  # 2.  Anything in "$(rbenv root)/versions/". This includes...
  #
  #     1.  `versions/<VERSION>/bin`, which gets stuck there by `rbenv-exec`:
  #
  #         <https://github.com/rbenv/rbenv/blob/59785f6762e9325982584cdab1a4c988ed062020/libexec/rbenv-exec#L45>
  #
  #         when running an executable installed by a Gem in that version.
  #
  #     2.  `versions/<VERSION>/gemsets/<GEMSET>/bin`, put there by
  #         `rbenv-gemset`:
  #
  #         <https://github.com/jf/rbenv-gemset/blob/6684504d684e520082a4e73382a7bb8d2c154a3b/etc/rbenv.d/exec/gemset.bash#L22>
  #         
  # 3.  Any `<P>/bin` where `P` is an entry in `GEM_PATH`, which are put there
  #     as part of the same process as (2.2), except for project-local gemset
  #     directories.
  #
  # We need these stripped paths because anything could have been happening 
  # before we got called, and we want to start clean before we either go
  # back in to a shim (which will add all it's stuff) or add the things we
  # need directly.
  #
  def clean_PATH : String
    exact = [
      Lock.rbenv.libexec_path,
    ]
    
    prefixes = [
      File.join( Lock.rbenv.root, "versions" ) + '/',
    ]
    
    if ( gem_path = ENV[ "GEM_PATH" ]? )
      gem_path.split( ':' ).each { |path| exact << File.join( path, "bin" ) }
    end
    
    ENV[ "PATH" ].
      split( ':' ).
      reject { |path|
        exact.any? { |bad_path| path == bad_path } \
        || prefixes.any? { |bad_start| path.starts_with? bad_start }
      }.
      join ':'
  end # #clean_PATH
  
  
  # Get an environment clean of all rbenv values, as well as the gem pathing
  # values `GEM_HOME` and `GEM_PATH`.
  # 
  # This is used as the starting point for the `Exe`'s execution environment 
  # `#env`.
  # 
  # We do this because we're never sure what's beeen going on before we were 
  # called, and the goal of `rbenv-lock` is to produce consistent execution
  # results regardless of where the lock executbale is called from.
  # 
  # Starting with a filtered environment shoudl help that.
  # 
  def clean_ENV : Hash(String, String)
    # ( {} of String => String ).tap { |env|
    #   ENV.each { |name, value| env[ name ] = value }
      
    ENV.to_h.tap { |env|
      env.reject! { |name, value|
        case name
        when /\ARBENV_/
          true
        when "GEM_HOME", "GEM_PATH"
          true
        else
          false
        end
      }
      
      env[ "PATH" ] = clean_PATH
    }
  end # clean_ENV
  
  
  def env : Hash(String, String)
    clean_ENV.tap do |env|
      # Any `name => nil` in `@env` means delete that name
      env.merge_and_delete_nils! @env
      
      env[ "RBENV_VERSION" ] = ruby_version
      
      # `direct?` sets things up to call *directly to the real bin, bypassing
      # `rbenv` entirely*. This might have serious speed advantages, but also
      # seems likely to be riddled with issues and brittle with regards to
      # future changes... but I made it work, so I'm going to leave the code in
      # here as an option.
      if direct?
        # Prefix the `PATH` with the bin dir for the Ruby version, like:
        # 
        #     "/Users/nrser/.rbenv/versions/2.3.6/bin:#{ ENV[ "PATH" ] }"
        # 
        # We omit the paths to `Rbenv::Client#libexec_path` and the rbenv hooks,
        # since we really shouldn't need them.
        # 
        env[ "PATH" ] = "#{ version_bin_dir }:#{ env[ "PATH" ] }"
      end
      
      # Are we using a gemset?
      if (
        (gemset = self.gemset) &&
        (gemset_dir = self.gemset_dir) &&
        (gemset_bin_dir = self.gemset_bin_dir)
      )
        # Set the gemset name so that `rbenv-gemset` will do the right thing
        # when going through the shims (when not `direct?`). This shouldn't 
        # really matter when we're `direct?`, but we want to remain close to
        # that environment, so it's good to have there too.
        env[ "RBENV_GEMSETS" ] = gemset
        
        # Are we going directly?
        if direct?
          # We need to do the work `rbenv-gemset` would have done...
          
          # Set `GEM_HOME` to the gemset's root, so that gems install there.
          env[ "GEM_HOME" ] = gemset_dir
          
          # We also want the gemset root at the front of the gem path.
          gem_path = gemset_dir
          
          # Unless shared gems are disabled (ENV var is absent or empty), append
          # the Ruby version's gem directory to the gem path so that gems from
          # there can be used too.
          if ENV.missing?( "RBENV_GEMSET_DISABLE_SHARED_GEMS" )
            gem_path = "#{ gem_path }:#{ ruby_version_gemdir }"
          end
          
          # Set the value
          env[ "GEM_PATH" ] = gem_path
          
          # Prepend the gemset's `bin` directory to the `PATH` so that those
          # executables take precidence.
          env[ "PATH" ] = "#{ gemset_bin_dir }:#{ env[ "PATH" ] }"
          
        end # if direct?
      end # if gemset?
      
      if (gem_name = self.gem_name)
        # This is really just for persistence
        env[ "RBENV_LOCK_GEM" ] = gem_name
        # I don't think we need the version? It's just for installing?
      end
      
    end # clean_ENV.tap
    
  end # #env
  
  
  def capture(
    command,
    args,
    shell = true,
    env : Hash(String, String?) = {} of String => String?,
  ) : { out: String, err: String, status: Process::Status }
    out_io = IO::Memory.new
    err_io = IO::Memory.new
    
    status = Process.run \
      command: command,
      args: args,
      shell: shell,
      env: self.env.merge_and_delete_nils!( env ),
      clear_env: true,
      output: out_io,
      error: err_io
    
    { out: out_io.to_s, err: err_io.to_s, status: status }
  end
  
  
  def stream(
    command,
    args,
    shell = true,
    env : Hash(String, String?) = {} of String => String?,
  ) : Process::Status
    Process.run \
      command: command,
      args: args,
      shell: shell,
      env: self.env.merge_and_delete_nils!( env ),
      clear_env: true,
      input: Process::Redirect::Inherit,
      output: Process::Redirect::Inherit,
      error: Process::Redirect::Inherit
  end # #stream
  
  
  # Swap the process out for a command run in the `#env`.
  # 
  def exec( command : String, args : Array(String) )
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
    exec command: command, args: args
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
