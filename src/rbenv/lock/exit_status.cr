# Namespace
# =======================================================================

module Rbenv
module Lock

  
# Definitions
# =======================================================================

enum ExitStatus
  OK = 0
  FAIL = 1
  
  def ok?
    self == OK
  end
  
  def fail?
    !ok?
  end
end

# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
