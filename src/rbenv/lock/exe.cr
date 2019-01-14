# Requirements
# =======================================================================

require "yaml"


# Namespace
# =======================================================================

module Rbenv
module Lock


# Definitions
# =======================================================================

# Runtime representation of a lock executable.
#
# Lock executables are files in the locks directores that act like
# reverse-shims: instead of one executable dynamically pointing to the
# approriate executable (which may or may not exist) for whatever Ruby version
# is enabled, locks always execute the target in a specific version of Ruby,
# regardless of what Ruby version is active.
# 
# Lock files are 
class Exe
  
  def self.load( path )
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
  end
  
  
  def self.path_for( name )
    File.join Env.locks_dir, name
  end
  
  
  # Instance Variables
  # ==========================================================================
  
  @name : String
  @target_path : String?
  @ruby_version : String
  @target : String
  @gemset : String?
  @gem_name : String?
  @path : String?
  @direct : Bool
  @env : Process::Env
  
  
  # Properties
  # ==========================================================================
  
  getter name : String
  getter ruby_version : String
  getter target : String
  getter gemset : String?
  getter gem_name : String?
  
  
  # Construction
  # ==========================================================================
  
  def initialize( @name,
                  @ruby_version,
                  @target,
                  @gemset = nil,
                  @gem_name = nil,
                  @path = nil,
                  @direct = false,
                  @env = {} of String => String? )
    
    # `@target_path` may require shell-outs, so leave it `nil` until needed
    # ({#target_path} resolves it dynamically)
    @target_path = nil
    
  end
  
  
  # Instance Methods
  # ==========================================================================
  
  def path : String
    @path ||= self.class.path_for name
  end
  
  
  def direct?
    @direct
  end
  
  
  def gemset?
    !@gemset.nil?
  end
  
  def version_bin_dir
    @version_bin_dir ||= \
      File.join Lock.rbenv.prefix( ruby_version ), "bin"
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
  
  
  def which( bin : String ) : String
    if direct?
      direct_version_bin_path = direct_version_bin_path_for bin
      
      # We're going to direct to the executable, so need to figure out if it's
      # in a gemset
      if (direct_gemset_bin_path = direct_gemset_bin_path_for bin)
        
        if bin == name
          # The lock bin will def be in the gemset
          direct_gemset_bin_path
          
        elsif {"gem", "ruby"}.includes?( bin )
          # These should always be in Ruby version (they come with it)
          direct_version_bin_path
          
        elsif File.exists?( direct_gemset_bin_path )
          # Ok, had to check... it is in the gemset
          direct_gemset_bin_path
        
        else
          # It's gotta be in the Ruby version
          direct_version_bin_path
        end
      else
        direct_version_bin_path
      end
    else
      # No direct, go to the shim
      Lock.rbenv.shim_path bin
    end
  end
  
  
  def target_path
    @target_path ||= which target
  end
  
  
  def env
    {} of String => String?
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
