# Namespace
# =======================================================================

module Rbenv


# Definitions
# =======================================================================

module Lock

  def self.rbenv : Client
    @@rbenv ||= Client.new
  end

end # module Lock


# /Namespace
# =======================================================================
  
end # module Rbenv::Lock