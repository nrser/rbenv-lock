# Requirements
# =======================================================================

### Stdlib ###

### Deps ###

require "nrser/log"

### Project / Package ###

require "../exit_status"
require "../env"
require "../core_ext/option_parser"


# Namespace
# =======================================================================

module Rbenv
module Lock
module Cmd


# Definitions
# =======================================================================

abstract class Base
  
  # Mixins
  # ==========================================================================
  
  include NRSER::Log
  
  
  # Class Properties
  # ==========================================================================
  
  class_getter aliases : Array( String ) = [] of String
  
  class_getter description : String = "(no description)"
  
  class_getter usage : String = "(no usage)"
  
  alias Example = {name: String, body: String}
  
  class_getter examples : Array(Example) = [] of Example
  
  
  # Class Methods
  # ==========================================================================

  def self.default_name : String
    self.name.to_s.split( "::" ).last.downcase
  end
  
  
  def self.canonical_name : String
    default_name
  end
  
  
  def self.names : Array(String)
    [ canonical_name ] + @@aliases
  end
  
  
  def self.examples_string
    String.build do |io|
      @@examples.join( io, '\n'  ) { |example, io|
        io << example[ :name ] << "\n\n"
        
        example[ :body ].
          lines( chomp: false ).
          each { |line| io << "    " << line }
      }
    end
  end
  
  
  # Instance Variables
  # ==========================================================================
  
  # Non-flag arguments *before* any `--`; only available after `parse!`
  @args : Array(String)
  
  # All arguments *after* any `--`; only available after `parse!`
  @double_dash_args : Array(String)
  
  # Exit status, which may be set during parsing to return before calling
  # `#on_run`
  @status : ExitStatus? = nil
  
  
  # Properties
  # ==========================================================================
  
  # All input arguments
  getter args_in : Array(String)
  
  # State flag to tell when we've `parse!`d
  property? parsed : Bool = false
  
  # The option parser
  getter parser : OptionParser
  
  # Where to write output.
  getter out_io : IO
  
  # Where to write error output
  getter err_io : IO
  
  
  # Construction
  # ==========================================================================
  
  def initialize(
    @args_in : Array( String ),
    @out_io : IO = STDOUT,
    @err_io : IO = STDERR,
  )  
    # NOTE: Seems like these don't get init'd until *after* this method body,
    #       which doesn't work for these since the parser needs them
    @args = [] of String
    @double_dash_args = [] of String
    
    # NOTE: For some reason, block init here started to hawk up compiler errors,
    #       can't figure out why... this bullshit:
    #       
    #           instance variable '@parser' of Rbenv::Lock::Cmd::Base was not 
    #           initialized directly in all of the 'initialize' methods, 
    #           rendering it nilable. Indirect initialization is not supported.
    #       
    @parser = OptionParser.new
    init_parser!
  end
    
    
  private def init_parser!
    parser = @parser

    title = "`rbenv lock #{ self.class.canonical_name }` Command"
    
    parser.banner = {
      title + "\n" + ("=" * title.size),
      @@description,
      "Usage:",
      "  #{ @@usage }",
    }.join "\n\n"
    
    parser.separator ""
    
    unless @@aliases.empty?
      parser.separator "Aliases: #{ @@aliases.join( ", " ) }"
      parser.separator ""
    end
    
    parser.separator "Options:"
    parser.separator ""
    
    init_options parser
    
    parser.on(
      "-q", "--quiet",
      "Be quiet - don't write messages to STDERR (help, errors",
      "warnings, etc.). ",
      " ",
      "Non-empty RBENV_LOCK_QUIET does the same thing,",
      "but takes effect immediately at program start instead of after",
      "options are parsed.",
      " ",
    ) do
      Rbenv::Lock::Env[ :quiet ] = 1
    end
    
    parser.on(
      "-d", "--debug",
      "Enable debug output (to STDERR).",
      " ",
      "Non-empty RBENV_LOCK_DEBUG does the same thing,",
      "but takes effect immediately at program start instead of after",
      "options are parsed.",
      " ",
    ) do
      Rbenv::Lock::Env[ :debug ] = 1
    end
    
    parser.on(
      "-h", "--help",
      "Show this message",
      " ",
    ) do
      out! parser
      self.status = ExitStatus::OK
    end
    
    parser.unknown_args do |before_double_dash, after_double_dash|
      @args = before_double_dash
      @double_dash_args = after_double_dash
    end
    
    parser.invalid_option do |flag|
      raise Error::User::Argument.new "#{ flag } is not a valid option."
    end
    
    unless @@examples.empty?
      parser.separator ""
      parser.separator "Examples:"
      parser.separator ""
      parser.separator self.class.examples_string
    end
  end
  
  
  protected def init_options( parser ) : Nil
  end
  
  
  # Instance Methods
  # ==========================================================================
  
  # State Management
  # --------------------------------------------------------------------------
  
  # Raise if we HAVE NOT `parsed?`
  # 
  protected def check_parsed! : Nil
    unless parsed?
      raise Error::Internal::State.new "Command has NOT YET been parsed!"
    end
  end
  
  
  # Raise if we HAVE `parsed?`
  # 
  protected def check_not_parsed! : Nil
    if parsed?
      raise Error::Internal::State.new "Command has ALREADY been parsed!"
    end
  end
  
  
  # Set the `#status`. Rasies if it's already been set.
  # 
  protected def status=( status : ExitStatus )
    unless @status.nil?
      raise Error::Internal::State.new "Status already set"  
    end
    
    @status = status
  end
  
  
  # State-Dependent Getters
  # --------------------------------------------------------------------------
  # 
  # These values are only acessible when we're in the correct state.
  # 
  
  def args : Array(String)
    check_parsed!
    @args
  end
  
  
  def double_dash_args : Array(String)
    check_parsed!
    @double_dash_args
  end
  
  
  def status : ExitStatus
    @status.not_nil!
  end
  
  
  # Writing
  # --------------------------------------------------------------------------
  
  def out!( *args ) : Nil
    @out_io.puts *args
    @out_io.flush
  end
  
  
  def err!( *args ) : Nil
    @err_io.puts *args
    @err_io.flush
  end
  
  
  # Running
  # --------------------------------------------------------------------------
  
  private def parse!
    check_not_parsed!
    
    debug "Parsing..!", args_in: args_in
    @parsed = true
    parser.parse args_in
    
    debug "Parsed.",
      args_in: args_in,
      args: args,
      double_dash_args: double_dash_args,
      status: @status
  end
  
  
  def run! : ExitStatus
    debug "Running #{ self.class.canonical_name }..."
    
    parse!
    
    if (status = @status)
      debug "Status set during parse, returning.", status: status
      return status
    end
    
    on_run.tap { |status|
      @status = status
      debug "`#on_run` completed, returning.", status: status
    }
  end # #run!
  
  
  # Abstract hook that realizing classes must implement.
  # 
  abstract def on_run : ExitStatus
  
  
end # class Base


# /Namespace
# =======================================================================

end # module Cmd
end # module Lock
end # module Rbenv
