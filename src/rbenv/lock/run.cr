# Requirements
# =======================================================================

### Deps ###

require "nrser/log"

# Project / Package
# -----------------------------------------------------------------------

require "./exit_status"
require "./cmd"


# Namespace
# =======================================================================

module Rbenv
module Lock

  
# Definitions
# =======================================================================

# Represents a run of the application.
# 
class Run
  
  include NRSER::Log
  
  getter args_in : Array(String)
  getter cmd : Cmd::Base? = nil
  getter out_io : IO
  getter err_io : IO
  
  
  def initialize(
    @args_in : Array(String) = ARGV,
    @out_io : IO = STDOUT,
    @err_io : IO = STDERR,
  )
    debug "Initializing...",
      args_in: args_in,
      out_io: out_io,
      err_io: err_io
  end
  
  
  def run! : ExitStatus
    debug "Starting run..."
    
    if args_in.empty?
      cmd_name = "help"
      cmd_args = [] of String
    else
      cmd_name = args_in[ 0 ]
      cmd_args = args_in[ 1..-1 ]
    end
    
    debug "Processed command", cmd_name: cmd_name, cmd_args: cmd_args
    
    cmd_class = Cmd.find! cmd_name
    
    cmd = @cmd = cmd_class.new( cmd_args, out_io: out_io, err_io: err_io )
    
    cmd.run!
  end
  
    
  def run
    begin
      run!
      
    rescue e : Error::User
      fatal e.message
      err_io.puts "For help:\n"
      if (cmd = self.cmd)
        err_io.puts "    rbenv lock help #{ cmd.class.canonical_name }\n"
      else
        err_io.puts "    rbenv lock help \n"
      end
      
      ExitStatus::FAIL
      
    rescue e : Error::Internal
      {% if flag?( :release ) %}
        fatal "An internal error occurred: #{ e.message }"
        ExitStatus::FAIL
      {% else %}
        raise e
      {% end %}
      
    rescue e : Exception
      {% if flag?( :release ) %}
        fatal "An unexpected error occurred: #{ e.message }"
        ExitStatus::FAIL
      {% else %}
        raise e
      {% end %}
      
    end # begin / rescue
  end # # .run
  
  
  def exec : NoReturn
    exit run.value
  end
  
end # class Run


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
