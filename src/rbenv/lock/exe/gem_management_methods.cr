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
    gem_name = self.gem_name?
    
    debug "Getting gemspec...", gem_name: gem_name
    
    if gem_name.nil?
      debug "No `#gem_name`, returning `nil`."
      return nil
    end
    
    capture = self.capture \
      command: gem_exe_path,
      args: { "specification", "specification", gem_name },
      direct: true
    
    debug "Captured gemspec",
      status: capture.status
    
    if capture.status.success?
      YAML.parse capture.output.gsub( /\!ruby\/\S+/, "" )
    end
  end
  
  
  # Get the version of the gem installed. If there is no `#gem_name` returns
  # `nil`.
  # 
  def installed_gem_version : String?
    gem_spec = self.gem_spec
    
    return nil if gem_spec.nil?
    
    gem_spec[ "version" ][ "version" ].as_s
  end
  
  
  # Is the gem installed? If there is no `#gem_name` returns `false`.
  # 
  def gem_installed? : Bool
    !installed_gem_version.nil?
  end
  
  
  # Is the associated `#gem_version` satisfied by the `#installed_gem_version`?
  # 
  # If there is no `#gem_name` returns `nil`.
  # 
  # If there is no `#gem_version`, returns `true` if there is any version 
  # installed, else `false`.
  # 
  def gem_version_satisfied? : Bool?
    # If we don't have a gem name, this whole thing makes no sense...
    return nil unless gem_name?
    
    if (required_version = gem_version?)
      # We have a version that's required
      
      if (installed_version = installed_gem_version)
        # And we have a version installed
        # See if they match!
        required_version == installed_version
      
      else
        # No version installed, can't be satisfied
        false
      end
      
    else
      # We have no version requirement, so any installed version will do
      !installed_gem_version.nil?
    end
  end # #gem_version_satisfied?
  
  
  # Install the associated Gem, if there is one and it's not at a satisfactory
  # version (see `#gem_version_satisfied?`).
  # 
  def ensure_gem : Nil
    install_gem! if gem_name? && !gem_version_satisfied?
  end
  
  
  # Install the lock executable's associated Gem. Will raise if the `Exe`
  # doesn't have one; use `#ensure_gem` in the general case.
  # 
  def install_gem!
    
    # We need to install the gem
    command = gem_exe_path
    args = [ "install", gem_name, ]
    
    # Specify the version if we have one
    if (gem_version = self.gem_version?)
      args << "--version"
      args << gem_version
    end
    
    info "Installing gem #{ gem_name }...",
      command: command,
      args: args
    
    status = stream \
      command: command,
      args: args,
      direct: true
    
    if status.success?
      info "Installed gem #{ gem_name }"
    else
      raise Error::External::Process.new \
        "Failed to install gem #{ gem_name }",
        command: command,
        args: args,
        status: status
    end
    
  end # #install_gem!
  
  
  
  # Remove the `#gem_name` gem.
  # 
  # Returns `true` if the Gem was removed, `false` if it wasn't (in which case
  # a warning is logged).
  # 
  def remove_gem : Bool
    if (gem_name = gem_name?)
      if gem_installed?
        info "Removing gem `#{ gem_name }` from Ruby #{ ruby_version }..."
        stream "gem", { "uninstall", gem_name }
        info "Gem `#{ gem_name }` removed from Ruby #{ ruby_version }."
        true
      else
        warn  "Gem `#{ gem_name}` is not installed," \
              "can't remove for lock `#{ name }`."
        false
      end
    else
      warn "Lock `#{ name }` does not have an associated gem, can't remove."
      false
    end
  end
  
end # class Exe


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
