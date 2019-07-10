##############################################################################
# `Rbenv::Lock::Exe` Create/Read/Update/Delete (CRUD) Methods
# ============================================================================
# 
# The `//src/rbenv/lock/exe.cr` file got a bit big and unwieldy by my standards,
# so I started to split it up. It is `require`d in the main `Exe` file and
# should **NOT** be loaded independently.
# 
# This file contains methods for managing the presence and content of locks.
# 
##############################################################################

# Namespace
# =======================================================================

module Rbenv
module Lock


# Definitions
# =======================================================================

class Exe

  # Class Methods
  # ==========================================================================
  
  # Load a lock up from it's `#name` or `#path`, raising `Error::User::Argument`
  # if it's not found.
  # 
  def self.load!( name_or_path : String ) : self
    name, path = if name_or_path.includes? File::SEPARATOR
      expanded = File.expand_path name_or_path
      { File.basename( expanded ), expanded }
    else
      { name_or_path, path_for( name_or_path ) }
    end
    
    unless File.file? path
      raise Error::User::Argument.new \
        "Lock executable #{ name.inspect } not found at `#{ path }"
    end
    
    contents = File.read path
    data = YAML.parse( contents ).as_h
    
    env = if data.has_key?( "env" )
      data[ "env" ].as_h.map { |k, v|
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
  end # .load!
  
  
  # Get a list of all locks in `.dir`.
  # 
  def self.list( quiet = false ) : Array(self)
    dir = self.dir
    
    locks = [] of self
    
    # Bail out `.dir` doesn't exist.
    unless File.directory?( dir )
      unless quiet
        warn "Locks directory `#{ dir }` does not exist!"
      end
      
      return locks
    end
    
    Dir.each_child( dir ) do |filename|
      path = File.join dir, filename
      
      if File.file?( path )
        begin
          locks << load!( path )
        rescue error : Exception
          unless quiet
            warn "Failed to load lock executable file at `#{ path }`"
          end
        end
      end
    end
    
    locks
  end # .list
  
  
  # Instance Methods
  # ==========================================================================
  
  # Wrapper around `write!` that raises `Error::User` if `#path` already exists.
  # 
  # Provide `true` for the *force* parameter if you want it to just `write!` 
  # regardless, clobbering anything that may have been there.
  # 
  def create( force : Bool = false, **kwds ) : Nil
    if force || !File.exists?( path )
      write **kwds
    else
      raise Error::User.new \
        "Lock file exists: #{ path }, use --force to overwrite"
    end
  end
  
  
  # Write the configuration to `#path`. Doesn't check what there or anything,
  # just goes for it. Use `#create` if you want to be a little more careful.
  # 
  def write( bin_only : Bool = false, mode : Int = 0o755 ) : Nil
    unless bin_only
      if (gemset_dir = self.gemset_dir)
        unless File.directory? gemset_dir
          FileUtils.mkdir_p gemset_dir, mode
        end
      end
      
      ensure_gem
    end
    
    Dir.mkdir_p( self.class.dir ) unless File.directory?( self.class.dir)
    
    File.open path, "w" do |file|
      file.puts "#!/usr/bin/env #{ self.class.exec_file_bin_path }"
      {
        ruby_version: ruby_version,
        target: target,
        gemset: gemset?,
        gem_name: gem_name?,
        direct: direct?,
        env: ( extra_env.empty? ? nil : extra_env.dup ),
      }.
        to_h.
        compact.
        to_yaml( file )
    end
    
    File.chmod path, mode
  end # #write
  
  
  # `rm` the `#path`.
  # 
  # Returns `true` if the file was removed, `false` if it wasn't (in which case
  # a warning is logged).
  # 
  def remove_path : Bool
    if path_exists?
      FileUtils.rm path
      info "Lock executable file for `#{ name }` at `#{ path }` removed."
      true
    else
      warn  "Lock executable file for `#{ name }` does not exist at " \
            "`#{ path }`, can't remove."
      false
    end
  end
  
  
  # Remove the `#gemset` by removing `#gemset_dir`.
  # 
  # Returns `true` if the file was removed, `false` if it wasn't (in which case
  # a warning is logged).
  # 
  def remove_gemset : Bool
    if (gemset_dir = self.gemset_dir)
      FileUtils.rm_rf gemset_dir
      info "Gemset `#{ gemset }` at `#{ gemset_dir }` removed."
      true
    else
      warn "Lock `#{ name }` does not have a gemset, can't remove."
      false
    end
  end
  
  
  # Flexible method for removing any, and, or all of:
  # 
  # 1.  The executable file at `#path` (see `#remove_path`).
  # 2.  The `#gem_name` Gem (see `#remove_gem`).
  # 3.  The `#gemset` at `#gemset_dir` (see `#remove_gemset`).
  # 
  # You can control which methods are called with the *path*, *gem* and *gemset*
  # `Bool` parameters.
  # 
  # When a parameter is omitted, each artifact ais removed it exists.
  # 
  # Returns a `Hash` reporting which artifacts were removed.
  # 
  def remove(
    path : Bool = path_exists?,
    gemset : Bool = !!self.gemset?,
    gem : Bool = gem_installed?,
  ) : { path: Bool?, gemset: Bool?, gem: Bool? }
    {
      path: (remove_path if path),
      gem: (remove_gem if gem),
      gemset: (remove_gemset if gemset),
    }
  end # #remove
  
  
  # Update the `#ruby_version` of the `Exe`, which removed the current one and
  # re-creates the new one (since new gems need to be installed).
  # 
  # -   *new_ruby_version* is the desired Ruby version as a string.
  # 
  # Returns the new `Env` instance.
  # 
  def update_ruby_version( new_ruby_version : String ) : self
    # 1.) Create a new `Exe` with the `#ruby_version` replaced
    new_exe = self.class.new \
      name: name,
      ruby_version: new_ruby_version,
      target: target,
      direct: direct?,
      env: extra_env,
      gemset: gemset?,
      gem_name: gem_name?,
      gem_version: gem_version?,
      path: path
    
    # 2.) Remove the bin file, so that it can be overwritten with the `new_exe`
    #     We'll put it back if creating the new `Exe` fails.
    remove_path
    
    # 3.) Create the `Exe`, putting the current bin file back if it fails
    begin
      new_exe.create
    rescue error : Error::User
      # Failed! - put the bin back for the current `Exe` and re-raise to the 
      # user
      write bin_only: true
      raise error
    end
    
    # 4.) Remove everything else for the current `Exe` (except the path, which
    #     was already removed in (2))
    remove path: false
    
    # 5.) Return the new `Exe`
    new_exe
  end # #update_ruby_version
  
end # class Exe


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
  