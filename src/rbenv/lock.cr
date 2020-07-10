# Requirements
# ============================================================================

### Project / Package ###

require "./client"


# Namespace
# =======================================================================

module Rbenv


# Definitions
# =======================================================================

# Namespace module for the `rbenv-lock` plugin.
#
# Locks are executable files in the locks directory (see `Exe.dir`) that act
# like reverse-shims: instead of one executable dynamically swapping to the
# executable for whatever Ruby is currently active, locks always swap out for
# the executable in a specific version of Ruby¹.
#
# NOTE
#
# > ¹ There are some facilities under development to dynamically select exactly
# which Ruby to use at execution time, like the support for `ruby-2.3` and such
# executables that pick the latest Ruby `~> 2.3.0`, allowing scripts to
# basically say "I need me some Ruby 2.3", and there may perhaps be something
# like `ruby-2.3+`, denoting `>= 2.3.0` or "I need at least Ruby 2.3.0", but the
# important part remains:
#
# > The version of Ruby executed depends only on the configuration of the lock
# and what's installed on the system, *not* on the currently active Ruby
# version.
#
module Lock
  @@rbenv : Client? = nil
  
  # `Client` for interacting with `rbenv`.
  # 
  def self.rbenv : Client
    @@rbenv ||= Client.new
  end

end # module Lock


# /Namespace
# =======================================================================
  
end # module Rbenv::Lock
