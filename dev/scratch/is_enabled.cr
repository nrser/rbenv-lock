##############################################################################
# Compile-Time Script to Test Log Level
# ============================================================================
# 
# This was me plyaing around with macro `run` commands to allow omitting of
# log methods entirely at compilation, which (like the 
# `nrser/babel-plugin-metalog` stuff I did) would let you cut logging below 
# a certain threshold out during compilation so that debug stuff could be left
# in at *no* performance penatly to release builds.
# 
# Use it like:
# 
#     {% if run(  "./log/is_enabled",
#                 Logger::Severity::WARN,
#                 env( "LOG_LEVEL" ) ) == "true" %}
# 
# I'm going to table it for now for simplicity's sake, but may come back at 
# some point. Writing it did help me understand the macro system much better.
# 
##############################################################################

require "logger"

def severity_for( string : String? ) : Logger::Severity
  return Logger::Severity.new( -1 ) if string.nil?
  
  if ( parsed = Logger::Severity.parse? string )
    return parsed
  end
  
  begin
    int = string.to_i
  rescue
    return Logger::Severity.new -1
  end
  
  if ( from_value = Logger::Severity.from_value? int )
    return from_value
  end
  
  return Logger::Severity.new -1
end

method_log_level = ARGV[ 0 ]
env_log_level = ARGV[ 1 ]

STDOUT << \
  ( severity_for( env_log_level ) <= severity_for( method_log_level ) ).to_s
