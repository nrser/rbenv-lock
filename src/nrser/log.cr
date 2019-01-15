# Requirements
# =======================================================================

### Stdlib ###

require "logger"

### Deps ###

### Project / Package ###


# Namespace
# =======================================================================

module  NRSER

  
# Definitions
# =======================================================================

# Eh, it's a start... I always want so much more from my logger, but fuck it
# can feel like a waste of time.
# 
module Log
  
  # Constants
  # ==========================================================================
  
  DEFAULT_FORMATTER = \
    Logger::Formatter.new do |severity, datetime, progname, message, io|
      label = severity.unknown? ? "ANY" : severity.to_s
      io << label.ljust( 6 ) << message
    end
  
  
  # Macros
  # ==========================================================================
  
  # Define a macro for each log level (severity, as Cyrs calls 'em)
  # 
  {% for name in Logger::Severity.constants %}
    
    macro {{ name.id.downcase }}( message )
      
      # If we're in a `--release` build, we totally omit `debug` messages by
      # having the `debug` macro expand to nothing!
      # 
      {% if !flag?( :release ) || name.id != "DEBUG" %}
      
        # Ok, we're either not `--release`, or we're not `DEBUG`, so we want
        # this macro to do something... which is grab the call site info and
        # hand off to `#log`.
        log \
          severity: Logger::Severity::{{ name.id }},
          file_path: \{{ message.filename }},
          line_number: \{{ message.line_number }},
          message: \{{ message }}
          
      {% end %} # if
      
    end # macro
    
  {% end %} # for severity names
  
  
  # Hooks
  # --------------------------------------------------------------------------
  
  # Define the singleton methods we're gonna need when included.
  # 
  macro included
    
    # Dynamically create the `Logger` instance. Override this to customize
    # how it happens (I think that will work? IDK I'm new here...).
    # 
    def self.logger : Logger
      @@logger ||= Logger.new \
        io: STDERR,
        formatter: NRSER::Log::DEFAULT_FORMATTER
    end
    
    
    # Format the final message and pass off to `.logger`'s `Logger#log`.
    # 
    protected def self.log(
      severity : Logger::Severity,
      message : String,
      file_path : String?,
      line_number : Int32?,
    )
      {% if flag?( :release ) %}
        # Omit the class and src loc shit when in a release
        logger.log severity, message
        
      {% else %}
      
        logger.log severity: severity do
          # Block is only executed if we're over severity.
          
          src_loc = "#{ file_path }:#{ line_number }"
          
          indented_message = message.lines.map { |line| "  #{ line }" }.join
          
          "{#{ self.name }} #{ src_loc }\n#{ indented_message }\n"
        end
        
      {% end %}
    end # .log
  
  end # macro included
  
  
  # Instance Methods
  # ==========================================================================
  
  # Just proxies up to `.log`.
  # 
  private def log( **kwds )
    self.class.log **kwds
  end

  
end # module Log


# /Namespace
# ============================================================================

end # module NRSER

