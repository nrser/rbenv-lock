# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------
require 'optparse'


# Declarations
# =======================================================================

module RbenvLock::Cmd; end


# Definitions
# =======================================================================

class RbenvLock::Cmd::Base
  
  include RbenvLock::Output
  
  DEFAULTS = {}
  OPTIONS = {}
  
  
  attr_reader :argv, :args, :options
  
  
  def initialize argv
    @argv = argv
    @args = nil
    @options = self.class::DEFAULTS.dup
  end
  
  
  def parser
    @parser ||= begin
      ::OptionParser.new do |parser|
        parser.banner = [
          self.class::DESCRIPTION,
          "Usage:",
          "  #{ self.class::USAGE }",
        ].join "\n\n"
        
        parser.separator ""
        
        parser.separator "Options:"
        
        self.class::OPTIONS.each do |name, config|
          if config[-1].is_a? Proc
            setter = ->( value ) {
              options[name] = config[-1].call value
            }
            config = config[0..-2]
          else
            setter = ->( value ) { options[name] = value}
          end
          
          parser.on *config, " ", &setter
        end
        
        parser.on(
          '-q', '--quiet',
          "Be quiet - don't write messages to STDOUT (errors, warnings, etc.)",
          " ",
          "Non-empty RBENV_LOCK_QUIET does the same thing.",
          " ",
        ) do
          RbenvLock::Env[:quiet] = 1
        end
        
        parser.on(
          '-d', '--debug',
          "Enable debug output (to STDERR).",
          " ",
          "Non-empty RBENV_LOCK_DEBUG does the same thing.",
          " ",
        ) do
          RbenvLock::Env[:debug] = 1
        end
        
        parser.on(
          "-h", "--help",
          "Show this message",
          " ",
        ) do
          err parser.to_s
          exit 1
        end
      end
    end
  end
  
  
  def parse!
    @args = @argv.dup
    parser.parse! @args
  end
  
  
  def run!
    parse!
    on_run
  end
  
end # module RbenvLock::Cmd
