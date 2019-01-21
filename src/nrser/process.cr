# Requirements
# =======================================================================

### Stdlib ###

### Deps ###

### Project / Package ###


# Namespace
# =======================================================================

module NRSER

# Definitions
# =======================================================================

class Process < ::Process
  
  struct Capture    
    getter output : String
    getter error : String
    getter status : ::Process::Status
    
    def initialize( @output, @error, @status )
    end
  end
  
  
  class Error < Exception
    
    TRIM_OUTPUTS_AT = 32
    
    # The capture from the `Process#capture!` that erred.
    getter status : ::Process::Status
    getter output : Nil | String | ::Process::Stdio
    getter error : Nil | String | ::Process::Stdio
    getter command : String
    getter args : Enumerable(String)?
    getter env : Env
    getter clear_env : Bool
    getter shell : Bool
    getter input : ::Process::Stdio
    getter chdir : String?
    
    
    def initialize(
      @status : ::Process::Status,
      @command : String,
      @args : Enumerable(String)?,
      @env : Env,
      @clear_env : Bool,
      @shell : Bool,
      @input : String | ::Process::Stdio,
      @output : String | ::Process::Stdio,
      @error : String | ::Process::Stdio,
      @chdir : String?,
    )
      super(
        String.build { |io|
          io << "Command " << @command
          
          if (args = @args)
            io << " with args "
            args.inspect io
          end
          
          if @status.normal_exit?
            io << " failed with exit code " << @status.exit_code
          else
            io << " was terminated with signal " << @status.exit_signal
          end
          
          error = @error
          output = @output
          
          if error.is_a?( String ) && !error.blank?
            io << " and error output: "
            if error.size > TRIM_OUTPUTS_AT
              io << error[ 0...TRIM_OUTPUTS_AT ] << "..."
            else
              io << error
            end
          elsif output.is_a?( String ) && !output.blank?
            io << " and output: "
            if output.size > TRIM_OUTPUTS_AT
              io << output[ 0...TRIM_OUTPUTS_AT ] << "..."
            else
              io << output
            end
          end
        }
      )
    end
    
  end # class Capture::Error
  
  
  # This method does essentially the same thing as Ruby's `Open3.capture3`,
  # returning the standard output and error as strings, well as the exiting
  # `::Process::Status` in a `Capture` instance.
  # 
  def self.capture(
    command : String,
    args : Enumerable(String)? = nil,
    env : Env = nil,
    clear_env : Bool = false,
    shell : Bool = false,
    input : ::Process::Stdio = ::Process::Redirect::Close,
    chdir : String? = nil,
  ) : Capture
    out_io = IO::Memory.new
    err_io = IO::Memory.new
    
    status = ::Process.run \
      command: command,
      args: args,
      env: env,
      clear_env: clear_env,
      shell: shell,
      input: input,
      output: out_io,
      error: err_io,
      chdir: chdir
    
    Capture.new output: out_io.to_s, error: err_io.to_s, status: status
  end # #capture
  
  
  def self.capture!(
    command : String,
    args : Enumerable(String)? = nil,
    env : Env = nil,
    clear_env : Bool = false,
    shell : Bool = false,
    input : ::Process::Stdio = ::Process::Redirect::Close,
    chdir : String? = nil,
  )
    capture = self.capture \
      command: command,
      args: args,
      env: env,
      clear_env: clear_env,
      shell: shell,
      input: input,
      chdir: chdir
    
    return capture if capture.status.success?
    
    raise Error.new \
      status: capture.status,
      command: command,
      args: args,
      env: env,
      clear_env: clear_env,
      shell: shell,
      input: input,
      output: capture.output,
      error: capture.error,
      chdir: chdir
    
  end # #capture!
  
  
  def self.out!( *args, **kwds ) : String
    capture!( *args, **kwds ).output
  end
  
  
  def self.out!( **kwds ) : String
    capture!( **kwds ).output
  end
  
  
  def self.chomp!( *args, **kwds ) : String
    out!( *args, **kwds ).chomp
  end
  
  
  def self.chomp!( **kwds ) : String
    out!( **kwds ).chomp
  end
  
end # class Process

# /Namespace
# =======================================================================

end # module NRSER
