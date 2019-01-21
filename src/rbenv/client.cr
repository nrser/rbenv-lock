require "shards/versions"

# Namespace
# =======================================================================

module  Rbenv


# Definitions
# =======================================================================

# A little client class for interacting with the `rbenv` CLI.
# 
class Client
  
  # Mixins
  # ==========================================================================
  
  include NRSER::Log
  
  
  # Class Methods
  # ========================================================================
  
  def self.quote( string : String ) : String
    "'" + string.gsub( "\\", "\\\\" ).gsub( "'", "\\'" ) + "'"
  end
  
  def self.quote( strings : Enumerable(String) ) : String
    return "" if strings.empty?
    
    strings.
      reject { |entry| entry.nil? }.
      map { |string| quote string }.
      join( " " )
  end
  
  @current : String? = nil
  @global : String? = nil
  @versions : Array(String)? = nil
  @env_PATH : String? = nil
  
  
  # Construction
  # ========================================================================
  
  def initialize
    @prefixes = {} of String => String
    @gem_dirs = {} of String => String
  end
  
  
  
  # Instance Methods
  # ========================================================================
  
  # Paths
  # --------------------------------------------------------------------------
  
  # Get absolute path to rbenv's `libexec` directory by resolving where the
  # `rbenv` executable really lives (since it's likely symlinked into 
  # `/usr/local/bin` or similar).
  #  
  # NOTE **Expensive**, **Cached** - Shells-out a `which rbenv` and then 
  # runs `File.real_path` on that result. Cached after first access.
  # 
  def libexec_path
    @libexec_path ||= File.dirname File.real_path( `which rbenv`.chomp )
  end
  
  
  # Absolute path to rbenv's `shims` directory.
  # 
  # Like `"$(rbenv root)/shims"` but avoids the 
  # 
  def shim_dir : String
    @shim_dir ||= File.join root, "shims"
  end
  
  
  # The absolute path to a shim executable, given the file's *name*.
  # 
  def shim_path( name : String ) : String
    File.join shim_dir, name
  end
  
  
  # Direct path to `gem` executable for a Ruby *version*.
  # 
  def gem_exe_path( version : String ) : String
    File.join( prefix( version ), "bin", "gem" )
  end
  
  
  # rbenv Command Execution
  # --------------------------------------------------------------------------
  
  def env_PATH : String
    @env_PATH = begin
      value = ENV[ "PATH" ]
      paths = value.split ":"
      
      if paths.includes? libexec_path
        value
      else
        "#{ libexec_path }:#{ value }"
      end
    end
  end
  
  
  def run!(
    subcmd : String | Symbol,
    args : Enumerable(String)? = nil
  ) : String
    
    path = File.join libexec_path, "rbenv-#{ subcmd }"
    env = { "PATH" => env_PATH }
    
    debug "Run!ing rbenv sub-command...",
      subcmd: subcmd,
      path: path
    
    out_io = IO::Memory.new
    err_io = IO::Memory.new
    
    status = Process.run \
      command: path,
      args: args,
      shell: false,
      env: env,
      clear_env: false,
      output: out_io,
      error: err_io
    
    if status.success?
      out_s = out_io.to_s
      
      debug "rbenv sub-command succeeded.",
        subcmd: subcmd,
        path: path,
        output: out_s
      
      return out_s
    end
      
    # We had an error...
    
    raise Lock::Error::External::Process.new \
      "Error running `rbenv-#[ subcmd }`:\n#{ err_io }"
    
  end # #run!
  
  
  # Overload to handle splat *args*.
  # 
  def run!( subcmd, *args : String ) : String
    run! subcmd, args
  end
  
  
  # rbenv Command API
  # --------------------------------------------------------------------------
  # 
  # Methods intended to produce the same results as running
  # 
  #     rbenv METHOD_NAME ARGS...
  # 
  # Though where-ever possible implemented *without* invoking sub-processes
  # (because they're *really* slow and quickly add up).
  # 
  
  # Absolute path to rbenv's root directory (where versions, shims, plugins,
  # etc. live).
  #
  # In order to avoid sub-shelling to `rbenv root`, implements essentially the
  # same algorithm: use the `RBENV_ROOT` env var if present, otherwise
  # `"~/.rbenv"`. Additionally runs `File.expand_path` on the result.
  #
  # NOTE **Cached** - Cached forever after first call.
  #
  def root : String
    @root ||= File.expand_path( ENV[ "RBENV_ROOT" ]? || "~/.rbenv" )
  end
  
  
  # Get the rbenv global Ruby version.
  #
  # In order to avoid sub-shelling to `rbenv global`, emulates their
  # functionality by looking for and reading the `"$(rbenv root)/version" file.
  #
  # NOTE *Somewhat-Expensive*, **Cached** - Reads the version file. Cached
  # forever after first call.
  #
  def global : String
    @global ||= begin
      path = File.join root, "version"
      
      if File.exists? path
        string = File.open( path, "r" ) { |f| f.gets limit: 1024 }
        
        if string.nil?
          # Assume system
          "system"
        else
          # Split by whitespace and get first word
          string.split( limit: 2 )[ 0 ]
        end
      else
        # Assume system
        "system"
      end
    end
  end # #global
  
  
  # Gets the name of the Ruby version currently active.
  # 
  # NOTE **Expensive**, **Cached** - executes `rbenv-version-name` in a 
  # sub-process. Result cached forever after first call.
  # 
  def current : String
    @current ||= run!( :"version-name" ).chomp
  end
  
  
  # Bare names of Ruby versions available via rbenv.
  # 
  # NOTE **Expensive**, **Cached** - executes `rbenv-versions` in a 
  # sub-process. Result cached forever after first call.
  # 
  # EXAMPLE
  #   
  #     RbenvLock::Rbenv.new.versions
  #     #=> ["2.0.0-p353", "2.3.7", "2.4.4", "2.5.1"]
  # 
  def versions : Array(String)
    @versions ||= run!( :versions, "--bare" ).lines.map( &.chomp )
  end
  
  
  # The `rbenv prefix` for the *version*, which is the version directory for
  # versions installed through rbenv, and usually `/usr` for `system`, such
  # that the `ruby` executable is at `PREFIX/bin/ruby`.
  # 
  # NOTE **Expensive**, **Cached** - executes `rbenv-prefix` in a 
  # sub-process. Result cached forever after first call (pre *version*).
  # 
  def prefix( version : String ) : String
    @prefixes[ version ] ||= run!( :prefix, version ).chomp
  end
  
  
  # Version Resolution
  # --------------------------------------------------------------------------
  # 
  # Additional functionality I added to select Ruby versions.
  # 
  
  # Resolves a list of Gem-style version *requirements* to one of `#versions`.
  # 
  # If multiple versions satisfy, chooses the latest (highest version number).
  # 
  # See the other overload for a version that handles exact version names,
  # as well as the special cases of "current" and "global".
  # 
  # NOTE **Expensive** on first call due to calling `#versions`.
  # 
  def version_for( requirements : Enumerable(String) ) : String
    Shards::Versions.resolve( versions, requirements ).last
  end # #version_for requirements
  
  
  # Resolves a *requirement* `String` to one of `#versions`. *requirement* can
  # be:
  # 
  # 1.  An exact version name (member of `#versions`, including `"system"`).
  # 2.  `"current"` for `#current`.
  # 3.  `"global" for `#global`.
  # 4.  A Gem-style requirement string like `~> 2.5.0`.
  # 
  # TODO What happens when it fails?
  # 
  def version_for( requirement : String ) : String
    case requirement
    when "current"
      current
    when "global"
      global
    else
      if versions.includes? requirement
        requirement
      else
        version_for requirements: { requirement }
      end
    end
  end # #version_for requirement
  
end # class Client


# /Namespace
# =======================================================================

end # module Rbenv
