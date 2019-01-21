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
  
  # Load a lock up from a `YAML` file path.
  # 
  def self.load( name_or_path ) : self
    path = if File.file? name_or_path
      name_or_path
    else
      path_for name_or_path
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
  
  
end # class Exe


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
  