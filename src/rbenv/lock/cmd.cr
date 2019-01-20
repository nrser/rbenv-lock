# Requirements
# =======================================================================

# Project / Package
# -----------------------------------------------------------------------

require "./exit_status"
require "./cmd/add"
require "./cmd/help"
require "./cmd/list"


# Namespace
# =======================================================================

module Rbenv
module Lock

  
# Definitions
# =======================================================================

module Cmd
  
  include NRSER::Log
  
  
  def self.all
    { Cmd::Add, Cmd::List, Cmd::Help }
  end
  
  
  def self.names : Array( String )
    all.map { |cls| cls.canonical_name }.to_a
  end
  
  
  def self.find( name : String )
    all.find { |cmd_class|
      debug "Checking command names for match...",
        cmd_class: cmd_class,
        names: cmd_class.names,
        name: name
    
      cmd_class.names.includes? name
    }
  end
  
  
  def self.find!( name : String )
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
