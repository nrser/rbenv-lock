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
  
  @env : Hash(String, String?)
  @gemdir : String?
  @gem_name : String?
  @gem_version : String?
  @gemset : String?
  @name : String
  @path : String?
  @ruby_version : String
  @target : String
  @target_path : String?
  
  
  # Properties
  # ==========================================================================
  
  getter gem_name : String?
  getter gem_version : String?
  getter gemset : String?
  getter name : String
  getter ruby_version : String
  getter target : String
  property? direct : Bool
  
  
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
    
    @path = if path.nil?
      nil
    else
      File.expand_path path
    end
    
    @env = {} of String => String?
    @env.merge!( env ) unless env.nil?
  end
  
  
  # Instance Methods
  # ==========================================================================
  
  
  # Does this lock use a gemset (required `rbenv-gemset` plugin)?
  # 
  # NOTE
  #
  # Not all that useful since the type system doesn't let you gaurd on this then
  # work as if `#gemset` is not `nil`, presumably because of concurrency..?
  # 
  def gemset?
    !@gemset.nil?
  end
  
  
  # Do we have a {#gem_name}?
  #
  # NOTE
  #
  # Not all that useful since the type system doesn't let you gaurd on this then
  # work as if `#gem_name` is not `nil`, presumably because of concurrency..?
  #
  def gem?
    !@gem_name.nil?
  end
  
  
end # class Exe


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
