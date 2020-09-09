# Requirements
# ============================================================================

### Stdlib ###

require "yaml"

### Project / Package ###

require "./base"
require "../exe"


# Namespace
# =======================================================================

module Rbenv
module Lock
module Cmd

# Definitions
# =======================================================================

# Exec locks.
# 
class Show < Base
  @@aliases = [ "status", "dump" ]
  
  @@description = %{See what's going on with a lock.}
  
  @@usage = "rbenv lock show NAME"
  
  @@examples = [
    {
      name: %{1. Basic usage},
      body: \
        %{    rbenv lock show qb\n} \
        %{\n}
    },
  ]
  
  
  def on_run : ExitStatus
    name = args[0]
    
    exe = Rbenv::Lock::Exe.load! name
    
    gem_data = if exe.gem_name?
      {
        name: exe.gem_name?,
        version: {
          required: exe.gem_version?,
          installed: exe.installed_gem_version,
          is_satisfied: exe.gem_version_satisfied?,
        },
        # spec: exe.gem_spec,
      }
    else
      {} of Symbol => Nil
    end
    
    data = {
      name: exe.name,
      path: exe.path,
      target: {
        name: exe.target,
        path: exe.target_path,
      },
      ruby_version: exe.ruby_version,
      direct: exe.direct?,
      env: exe.env( {} of String => String ),
      gemset: exe.gemset?,
      gem: gem_data,
    }
    
    YAML.dump data, STDOUT
    
    ExitStatus::OK
  end
  
end # class Show


# /Namespace
# =======================================================================

end # module Cmd
end # module Lock
end # module Rbenv
