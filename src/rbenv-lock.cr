##############################################################################
# rbenv-lock Plugin Entry Point
# ============================================================================
#
# Produces the `//bin/rbenv-lock` binary that `rbenv lock` points to.
#
##############################################################################

require "nrser/log"
require "./rbenv/lock/core_ext/ENV"
require "./rbenv/lock/run"

if ENV.present?( "RBENV_LOCK_DEBUG" )
  {% if flag?( :release ) %}
    # Flip to `-debug` version...
    Process.exec command: "#{ Process.executable_path }-debug", args: ARGV
  {% else %}
    # Set the log level
    NRSER::Log.level = ::Log::Severity::Debug
  {% end %}
end

NRSER::Log.setup()

Rbenv::Lock::Run.new( ARGV ).exec
