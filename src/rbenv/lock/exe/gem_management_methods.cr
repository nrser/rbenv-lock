##############################################################################
# `Rbenv::Lock::Exe` Gem Managements Methods
# ============================================================================
# 
# The `//src/rbenv/lock/exe.cr` file got a bit big and unwieldy by my standards,
# so I started to split it up. It is `require`d in the main `Exe` file and
# should **NOT** be loaded independently.
# 
# This file contains methods for managing the Gem that may be associated with
# the lock `Exe`.
# 
##############################################################################

# Namespace
# =======================================================================

module Rbenv
module Lock


# Definitions
# =======================================================================

class Exe
  
  
  # Instance Methods
  # ==========================================================================
  
  def gem_spec : YAML::Any?
    gem_name = self.gem_name.not_nil!
    
    capture = self.capture \
      command: gem_exe_path,
      args: { "specification", "--local", gem_name }
    
    if capture[ :status ].success?
      YAML.parse capture[ :out ]
    end
  end
  
  
  def ensure_gem : Nil
    gem_spec = self.gem_spec
    gem_version = self.gem_version
    gem_name = self.gem_name.not_nil!
    
    # If the gem is not installed or isn't the right version...
    if  gem_spec.nil? ||
        (gem_version && gem_spec[ :version ].as_s != gem_version)
    
      # We need to install the gem
      command = gem_exe_path
      args = [ "install", gem_name, ]
      
      # Specify the version if we have one
      if gem_version
        args << "--version"
        args << gem_version
      end
      
      info "Installing gem #{ gem_name }...",
        command: command,
        args: args
      
      status = stream \
        command: command,
        args: args
      
      if status.success?
        info "Installed gem #{ gem_name }"
      else
        raise Error::External::Process.new \
          "Failed to install gem #{ gem_name }",
          command: command,
          args: args,
          status: status
      end
    end # if need to install
  end # #ensure_gem
  
end # class Exe


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
