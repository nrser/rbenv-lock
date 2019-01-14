require "./rbenv_lock/rbenv"

module RbenvLock

  def self.rbenv : Rbenv
    @@rbenv ||= Rbenv.new
  end
  
end # module RbenvLock