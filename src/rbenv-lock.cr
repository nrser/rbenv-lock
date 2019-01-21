##############################################################################
# rbenv-lock Plugin Entry Point
# ============================================================================
#
# Produces the `//bin/rbenv-lock` binary that `rbenv lock` points to.
#
##############################################################################

require "./nrser/reason"
require "./nrser/log"
require "./nrser/process"
require "./rbenv/**"

if ENV.present?( "RBENV_LOCK_DEBUG" )
  {% if flag?( :release ) %}
    # Flip to `-debug` version...
    Process.exec command: "#{ Process.executable_path }-debug", args: ARGV
  {% else %}
    # Set the log level
    NRSER::Log.level = Logger::DEBUG
  {% end %}
end

Rbenv::Lock::Run.new( ARGV ).exec
