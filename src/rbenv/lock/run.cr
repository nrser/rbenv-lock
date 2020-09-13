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
    
    pair = args_in.each_with_index.find do |arg_in, index|
      arg_in == "-h" || arg_in == "--help" || arg_in[0] != '-'
    end
    
    cmd_args_in = args_in.dup
    
    if pair.nil?
      cmd_name_arg = nil
    else
      cmd_name_arg, index = pair
      cmd_args_in.delete_at index
    end
    
    debug "Processed command", name_arg: cmd_name_arg, args_in: cmd_args_in
    
    cmd_class = Cmd.find! cmd_name_arg
    
    cmd = @cmd = cmd_class.new( cmd_name_arg,
                                cmd_args_in,
                                out_io: out_io,
                                err_io: err_io )
    
    cmd.run!
  end
  
    
  def run
    begin
      run!
      
    rescue e : Error::User
      fatal e.message
      
      if (cmd = self.cmd)
        usage = cmd.class.usage
        help = "rbenv lock #{ cmd.class.canonical_name } --help"
      else
        usage = Cmd::Help.usage
        help = "rbenv lock help"
      end
      
      err_io.puts usage
      err_io.puts "Additional help:\n    #{help}\n"
      
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
