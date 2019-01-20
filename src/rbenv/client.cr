require "shards/versions"

# Namespace
# =======================================================================

module  Rbenv


# Definitions
# =======================================================================

# A little client class for interacting with the `rbenv` CLI.
# 
class Client
  
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
  
  
  # Construction
  # ========================================================================
  
  def initialize
    @prefixes = {} of String => String
    @gem_dirs = {} of String => String
  end
  
  
  
  # Instance Methods
  # ========================================================================
  
  def run( cmd : String | Symbol ) : String
    shell_string =  "rbenv-#{ cmd } 2>/dev/null || rbenv #{ cmd }"
    
    `#{ shell_string }`
  end
  
  
  def run( cmd : String | Symbol, *args : String ) : String
    args_s = self.class.quote args
    
    shell_string = \
      "rbenv-#{ cmd } #{ args_s } 2>/dev/null || rbenv #{ cmd } #{ args_s }"
    
    `#{ shell_string }`
  end
  
  
  # Absolute path to 
  # 
  def root : String
    @root ||= ENV[ "RBENV_ROOT" ]? || run( :root ).chomp
  end
  
  
  def global : String
    @global ||= run( :global ).chomp
  end
  
  
  def current : String
    @current ||= run( :"version-name" ).chomp
  end
  
  
  # Bare names of Ruby versions installed via rbenv.
  # 
  # EXAMPLE
  #   
  #     RbenvLock::Rbenv.new.versions
  #     #=> ["2.0.0-p353", "2.3.7", "2.4.4", "2.5.1"]
  # 
  def versions : Array(String)
    @versions ||= run( :versions, "--bare" ).lines.map( &.chomp )
  end
  
  
  def version_for( requirements : Enumerable(String) ) : String
    Shards::Versions.resolve( versions, requirements ).last
  end
  
  
  def version_for( requirement : String ) : String
    case requirement
    when "current"
      current
    when "global"
      global
    else
      version_for requirements: { requirement }
    end
  end
  
  
  def prefix( version : String ) : String
    @prefixes[ version ] ||= run( :prefix, version ).chomp
  end
  
  
  def shim_dir : String
    @shim_dir ||= File.join root, "shims"
  end
  
  
  def shim_path( bin : String ) : String
    File.join shim_dir, bin
  end
  
  
  def libexec_path
    @libexec_path ||= File.dirname File.real_path( `which rbenv`.chomp )
  end
  
  
  # Direct path to `gem` executable for a *version*.
  # 
  def gem_exe_path( version : String ) : String
    File.join( prefix( version ), "bin", "gem" )
  end
  
end # class Client


# /Namespace
# =======================================================================

end # module Rbenv
