# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------

# require "./output"


# Namespace
# =======================================================================

module  RbenvLock


# Definitions
# =======================================================================

# @todo document Rbenv class.
class Rbenv

  # include Output
  
  # Constants
  # ========================================================================
  
  
  # Singleton Methods
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
  
  
  # Construction
  # ========================================================================
  
  def initialize
    @prefixes = {} of String => String
  end
  
  
  
  # Instance Methods
  # ========================================================================
  
  def run( cmd : Symbol ) : String
    shell_string =  "rbenv-#{ cmd } 2>/dev/null || rbenv #{ cmd }"
    
    `#{ shell_string }`
  end
  
  
  def run( cmd : Symbol, *args : String ) : String
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
  
  
  def versions : Array(String)
    @versions ||= run( :versions, "--bare" ).lines.map( &:chomp )
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
  
end # class Rbenv


# /Namespace
# =======================================================================

end # module RbenvLock
