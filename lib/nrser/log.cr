# Requirements
# =======================================================================

### Stdlib ###

require "log"

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
    
  DEFAULT_FORMATTER = ::Log::Formatter.new do |entry, io|
    label = entry.severity.none? ? "ANY" : entry.severity.label
    io << label.ljust( 6 )
    
    if file_path = entry.data[:file_path]?
      unless entry.source.empty?
        io << '{' << entry.source << '}' << ' '
      end
      
      io << file_path
      
      if line_number = entry.data[:line_number]?
        io << ':' << line_number
      end
    end
    
    io << '\n'
    
    if !entry.message.empty?
      entry.message.lines.each { |line| io << "  "; io << line }
      io << '\n'
    end
    
    if values_str = entry.data[:values_str]?
      io << values_str
    end
  end
  
  
  # Macros
  # ==========================================================================
  
  # Define a macro for each log level (severity, as Cyrs calls 'em)
  # 
  {% for name in {  "trace",
                    "debug",
                    "info",
                    "notice",
                    "warn",
                    "error",
                    "fatal" } %}
    
    macro {{ name.id }}( message )
      {% if flag?( :release ) %}
        # In release builds we omit the file path and line number.
        # 
        # We also have the `.debug` macro expand to nothing, simple omitting 
        # those calls from the compiled code.
        # 
        {% if name.id != "debug" %}
          log.{{ name.id }} { \{{ message }} || "" }
        {% end %}
      {% else %}
        # The `:release` flag is not set, so this is a debug build, meaning
        # we want to include the file path and line number
        log.{{ name.id }} &.emit(
          \{{ message }} || "",
          file_path: \{{ message.filename }},
          line_number: \{{ message.line_number }},
        )
      {% end %}
    end # macro
  
    
    macro {{ name.id }}( message, **values )
      {% if flag?( :release ) %}
        # In release builds we omit the file path and line number.
        # 
        # We also have the `.debug` macro expand to nothing, simple omitting 
        # those calls from the compiled code.
        # 
        {% if name.id != "debug" %}
          self.log.{{ name.id }} &.emit(
            \{{ message }} || "",
            values_str: NRSER::Log.format_values(( \{{ values }} ).to_h),
          )
        {% end %}
      {% else %}
        # The `:release` flag is not set, so this is a debug build, meaning
        # we want to include the class name, file path and line number
        self.log.{{ name.id }} &.emit(
          \{{ message }} || "",
          file_path: \{{ message.filename }},
          line_number: \{{ message.line_number }},
          values_str: NRSER::Log.format_values(( \{{ values }} ).to_h),
        )
      {% end %}
    end # macro
    
  {% end %} # for severity names
  
  
  # Hooks
  # --------------------------------------------------------------------------
  
  # Define the singleton methods we're gonna need when included.
  # 
  macro included
    
    @@log : ::Log? = nil
    
    # Dynamically create the `::Log` instance. Override this to customize
    # how it happens (I think that will work? IDK I'm new here...).
    # 
    def self.log : ::Log
      @@log ||= ::Log.for self
    end
  
  end # macro included
  
  
  @@level : ::Log::Severity = ::Log::Severity::Info
  
  # Singleton Methods
  # ==========================================================================
  
  def self.setup(level : ::Log::Severity = @@level) : Nil
    ::Log.setup(
      level: @@level,
      backend: ::Log::IOBackend.new(formatter: DEFAULT_FORMATTER)
    )
  end
  
  
  def self.format_values( values : Hash, indent = 4 ) : String
    String.build( 256 ) do |io|
      values.each do |name, value|
        io << (" " * indent) << name << ": "
        # io << name
        # io << ": "
        PrettyPrint.format( value, io, width: 79, indent: indent + 2 )
        io << '\n'
      end
    end
  end
  
  
  def self.level : ::Log::Severity
    @@level
  end
  
  
  def self.level=( level : ::Log::Severity )
    @@level = level
  end
  
  
  # Instance Methods
  # ==========================================================================
  
  # Just proxies up to `.log`.
  # 
  private def log : ::Log
    self.class.log
  end

  
end # module Log


# /Namespace
# ============================================================================

end # module NRSER

