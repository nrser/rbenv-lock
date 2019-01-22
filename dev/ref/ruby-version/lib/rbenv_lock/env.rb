module RbenvLock; end

module RbenvLock::Env
  VAR_PREFIX = 'RBENV_LOCK'
  
  def self.var_name key
    "#{ VAR_PREFIX }_#{ key.to_s.upcase }"
  end
  
  def self.[] key
    ENV[ var_name( key ) ]
  end
  
  def self.[]= key, value
    ENV[ var_name( key ) ] = value.to_s
  end
  
end # module RbenvLock::Env
