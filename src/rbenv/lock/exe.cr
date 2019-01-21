# Requirements
# ============================================================================

### Stdlib ###

require "yaml"
require "file_utils"

### Project / Package ###

#### Sub-Tree ####
#
# This file got a bit big and unwieldy by my standards,
# so I started to split it up.
# 
require "./exe/crud_methods"
require "./exe/environment_methods"
require "./exe/gem_management_methods"
require "./exe/path_methods"
require "./exe/subprocess_methods"


# Namespace
# =======================================================================

module Rbenv
module Lock


# Definitions
# =======================================================================

# Runtime representation of a lock executable. Includes methods to write 
# lock files, read them back in, and `exec` in their environment.
# 
# Lock executables live in {.dir}, and are simply executable YAML files whose
# "shebang" lines point to `//bin/rbenv-lock-exec-file`. Hence the executables
# serve as the database as well, each containing all the data for a particular
# lock.
# 
class Exe
  
  # Constants
  # ==========================================================================
  
  # TODO Still needed?
  # 
  DIRTY_ENV_NAMES = {
    "GEM_HOME",
    "GEM_PATH",
    "RBENV_DIR",
    "RBENV_HOOK_PATH",
    "RBENV_VERSION",
    
    # Additional places that Ruby will search when `require`ing.
    "RUBYLIB",
  }
  
  
  # Mixins
  # ==========================================================================
  
  # Add logging support
  include NRSER::Log
  
  
  # Instance Variables
  # ==========================================================================
  
  ## Dynamically Populated (Cache) Variables ##
  #
  # Instance variables that are either *expensive* (requiring a
  # shell-out/subprocess or file-system check) to populate, and are hence
  # resolved on demand via their associated methods.
  #
  
  # Cache for `#ruby_version_gemdir`, which runs the `gem` executable for the
  # `#ruby_version` to find the `gem env gemdir` value.
  @ruby_version_gemdir : String?
  
  # Requires calling `#which`, which *at least* may hit the file system, and
  # likely can shell-out too when you consider the paths it needs.
  @target_path : String?
  
  
  # Properties
  # ==========================================================================
  
  ## Required Instance Variables ##

  getter  name : String
  getter  ruby_version : String
  getter  target : String
  getter  path : String
  getter? direct : Bool
  
  # Any additional environment variables defined in the lock executable file
  # that are merged in to the execution `#env`.
  # 
  # `nil` values mean to remove those variables when merging.
  # 
  getter extra_env : Hash(String, String?)
  
  ## Optional Instance Variables ##
  
  getter! gem_name : String?
  getter! gem_version : String?
  getter! gemset : String?
  
  
  # Construction
  # ==========================================================================
  
  def initialize( @name,
                  @ruby_version,
                  @target,
                  @direct = false,
                  env : Process::Env = nil,
                  @gemset = nil,
                  @gem_name = nil,
                  @gem_version = nil,
                  path = nil, )
    
    # `@target_path` may require shell-outs, so leave it `nil` until needed
    # (`#target_path` resolves it dynamically)
    @target_path = nil
    
    # Set the `#path`
    @path = if path.nil?
      self.class.path_for @name
    else
      File.expand_path path
    end
    
    @extra_env = {} of String => String?
    @extra_env.merge!( env ) unless env.nil?
  end # #initialize
  
end # class Exe


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
