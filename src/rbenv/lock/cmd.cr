# Requirements
# =======================================================================

### Deps ###

require "nrser/log"

## Project / Package ##

require "./exit_status"
require "./error"
require "./cmd/add"
require "./cmd/exec"
require "./cmd/help"
require "./cmd/list"
require "./cmd/remove"
require "./cmd/show"
require "./cmd/update"


# Namespace
# =======================================================================

module Rbenv
module Lock

  
# Definitions
# =======================================================================

module Cmd
  
  include NRSER::Log
  
  
  def self.all
    {
      Cmd::List,
      Cmd::Show,
      Cmd::Add,
      Cmd::Update,
      Cmd::Remove,
      Cmd::Exec,
      Cmd::Help,
    }
  end
  
  
  def self.names : Array( String )
    all.map { |cls| cls.canonical_name }.to_a
  end
  
  
  def self.find( name : String? )
    if name.nil?
      Cmd::Help
    else
      all.find { |cmd_class|
        debug "Checking command names for match...",
          cmd_class: cmd_class,
          names: cmd_class.names,
          name: name
      
        cmd_class.names.includes? name
      }
    end
  end
  
  
  def self.find!( name : String? )
    find( name ).
      tap { |cmd_class|
        if cmd_class.nil?
          raise Error::User::Argument.new \
            "Bad command: #{ name.inspect }\n" \
            "Available:\n#{ names.join( "\n" ) }"
        end
      }.
      not_nil!
  end
  
end # module Cmd


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
