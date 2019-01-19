# Requirements
# ============================================================================

### Stdlib ###

require "yaml"

### Deps ###

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

# List locks.
# 
# @example 1.  Basic usage
#       rbenv lock list
#   
#   Output looks like `<BIN>: <VERSION>`.
# 
# @example 2.  List details
#       rbenv lock list --long
#   
#   Lock details are written in YAML format.
# 
class List < Base
  @@aliases = [ "ls" ]
  
  @@description = "List locks."
  
  @@usage = "rbenv lock list [OPTIONS]"
  
  @@examples = [
    {
      name: "1. Basic Usage",
      body: \
        "    rbenv lock list\n" \
        "\n" \
        "Output looks like `<BIN>: <VERSION>`.\n"
    },
    
    {
      name: "2. List details",
      body: \
        "    rbenv lock list --long\n" \
        "\n" \
        "Lock details are written in YAML format.\n"
    }
  ]
  
  property? long : Bool = false
  
  protected def init_options( parser ) : Nil
    parser.on(
      "-l", "--long",
      "Print lock details (YAML format)",
    ) { @long = true }
  end
  
  
  def on_run
    debug "RUNNING `list` command...", argv: argv
    
    locks = Rbenv::Lock::Exe.list
    
    if long?
      locks.
        map { |lock|
          {
            "name"    => lock.name,
            "ruby"    => lock.ruby_version,
            "gem"     => lock.gem_name,
            "gemset"  => lock.gemset,
            "path"    => lock.path,
            "target"  => lock.target,
          }.reject { |k, v| v.nil? }
        }.
        to_yaml( out_io )
    else
      locks.each { |lock| out! "#{ lock.name }: #{ lock.ruby_version }" }
    end
    
    ExitStatus::OK
  end
  
end # class List


# /Namespace
# =======================================================================

end # module Cmd
end # module Lock
end # module Rbenv
