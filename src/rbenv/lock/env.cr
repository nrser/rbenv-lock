# Namespace
# =======================================================================

module Rbenv
module Lock


# Definitions
# =======================================================================

module Env
  VAR_PREFIX = "RBENV_LOCK"
  
  def self.var_name( key )
    "#{ VAR_PREFIX }_#{ key.to_s.upcase }"
  end
  
  def self.[]( key )
    ENV[ var_name( key ) ]
  end
  
  def self.[]=( key, value )
    ENV[ var_name( key ) ] = value.to_s
  end
  
  def self.locks_dir
    File.expand_path(
      self[ :locks_dir ] ||
      File.join( Rbenv::Lock.rbenv.root, "locks" )
    )
  end
end # module Env


# /Namespace
# =======================================================================

end # moudle Lock
end # module Rbenv
