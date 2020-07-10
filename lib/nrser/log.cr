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
    ::Logger::Formatter.new do |severity, datetime, progname, message, io|
      label = severity.unknown? ? "ANY" : severity.to_s
      io << label.ljust( 6 ) << message
    end
  
  
  # Macros
  # ==========================================================================
  
  # Define a macro for each log level (severity, as Cyrs calls 'em)
  # 
  {% for name in ::Logger::Severity.constants %}
    
    macro {{ name.id.downcase }}( message )
          
      # If we're in a `--release` build, we totally omit `debug` messages by
      # having the `debug` macro expand to nothing!
      # 
      {% if !flag?( :release ) || name.id != "DEBUG" %}
      
        # Ok, we're either not `--release`, or we're not `DEBUG`, so we want
        # this macro to do something... which is grab the call site info and
        # hand off to `#log`.
        log \
          severity: ::Logger::Severity::{{ name.id }},
          file_path: \{{ message.filename }},
          line_number: \{{ message.line_number }},
          message: \{{ message }}
          
      {% end %} # if
      
    end # macro
  
    
    macro {{ name.id.downcase }}( message, **values )
      
      # If we're in a `--release` build, we totally omit `debug` messages by
      # having the `debug` macro expand to nothing!
      # 
      {% if !flag?( :release ) || name.id != "DEBUG" %}
      
        # Ok, we're either not `--release`, or we're not `DEBUG`, so we want
        # this macro to do something... which is grab the call site info and
        # hand off to `#log`.
        log \
          severity: ::Logger::Severity::{{ name.id }},
          file_path: \{{ message.filename }},
          line_number: \{{ message.line_number }},
          message: \{{ message }},
          values: ( \{{ values }} ).to_h
          
      {% end %} # if
      
    end # macro
    
  {% end %} # for severity names
  
  
  # Hooks
  # --------------------------------------------------------------------------
  
  # Define the singleton methods we're gonna need when included.
  # 
  macro included
    @@logger : ::Logger? = nil
    
    # Dynamically create the `::Logger` instance. Override this to customize
    # how it happens (I think that will work? IDK I'm new here...).
    # 
    def self.logger : ::Logger
      @@logger ||= ::Logger.new \
        io: STDERR,
        formatter: NRSER::Log::DEFAULT_FORMATTER,
        level: NRSER::Log.level
    end
    
    
    # Format the final message and pass off to `.logger`'s `::Logger#log`.
    # 
    protected def self.log(
      severity : ::Logger::Severity,
      message : String?,
      values : Hash? = nil,
      file_path : String? = nil,
      line_number : Int32? = nil,
    )
      {% if flag?( :release ) %}
        # Omit the class and src loc shit when in a release
        if values.nil? || values.empty?
          logger.log severity, message
        else
          logger.log severity do
            String.build do |io|
              if message
                io << message << "\n"
              end
              
              NRSER::Log.format_values( values, io: io, indent: 2 )
            end
          end
        end
        
      {% else %}
      
        logger.log severity do
          # Block is only executed if we're over severity.
          
          String.build( 256 ) do |io|
            io << '{'
            io << self.name
            io << '}'
            
            if file_path
              io << file_path
              
              if line_number
                io << ':'
                io << line_number
              end
            end
            
            io << '\n'
            
            if message
              message.lines.each { |line| io << "  "; io << line }
              io << '\n'
            end
            
            unless values.nil? || values.empty?
              NRSER::Log.format_values( values, io: io, indent: 4 )
            end
          end
        end
        
      {% end %}
    end # .log
  
  end # macro included
  
  
  @@level : ::Logger::Severity = ::Logger::INFO
  
  
  # Singleton Methods
  # ==========================================================================
  
  def self.format_values( values : Hash, indent : String = "  " ) : String
    values.
      map { |name, value|
        "#{ indent }#{ name }: " +
        value.pretty_inspect.lines.join( "#{ indent }  " )
      }.
      join( "\n" ) + "\n"
  end
  
  
  def self.format_values( values : Hash, io : IO, indent = 2 ) : Nil
    values.each do |name, value|
      io << (" " * indent) << name << ": "
      # io << name
      # io << ": "
      PrettyPrint.format( value, io, width: 79, indent: indent + 2 )
      io << '\n'
    end
  end
  
  
  def self.level : ::Logger::Severity
    @@level
  end
  
  
  def self.level=( level : ::Logger::Severity )
    @@level = level
  end
  
  
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

