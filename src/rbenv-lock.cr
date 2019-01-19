##############################################################################
# rbenv-lock Plugin Entry Point
# ============================================================================
#
# Produces the `//bin/rbenv-lock` binary that `rbenv lock` points to.
#
##############################################################################

require "./nrser/log"
require "./rbenv/**"

if ENV.present?( "RBENV_LOCK_DEBUG" )
  {% if flag?( :release ) %}
    # Flip to `-debug` version...
    Process.exec command: "#{ PROGRAM_NAME }-debug", args: ARGV
  {% else %}
    # Set the log level
    NRSER::Log.level = Logger::DEBUG
  {% end %}
end

Rbenv::Lock::Cmd.exec ARGV
