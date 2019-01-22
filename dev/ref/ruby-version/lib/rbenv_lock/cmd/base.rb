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
  
  ALIASES = []
  DEFAULTS = {}
  OPTIONS = {}
  
  
  def self.subclasses
    @subclasses ||= []
  end
  
  
  def self.inherited subclass
    subclasses << subclass
  end
  
  
  def self.names
    [self::NAME] + self::ALIASES
  end
  
  
  def self.examples
    @examples ||= begin
      dir = File.expand_path '..', __FILE__
      contents = File.read File.join( dir, self::NAME + '.rb' )
      
      examples = []
      example = nil
      
      header = '# @example '
      body = '#   '
      
      contents.lines.each do |line|
        if line.start_with? header
          unless example.nil?
            examples << example
          end
          
          example = {
            name: line[header.length..-1].chomp,
            lines: [],
          }
        elsif example && line.start_with?( body )
          example[:lines] << line[body.length..-1].chomp
        elsif example
          examples << example
          example = nil
        end
      end
      
      examples
    end
  end
  
  
  def self.examples_string
    examples.map { |example|
      example[:name] + "\n\n" + example[:lines].map { |line|
        "    " + line
      }.join( "\n" )
    }.join( "\n\n" ) + "\n\n"
  end
  
  
  attr_reader :argv, :args, :options
  
  
  def initialize argv
    @argv = argv
    @args = nil
    @options = self.class::DEFAULTS.dup
  end
  
  
  def parser
    @parser ||= begin
      ::OptionParser.new do |parser|
        title = "`rbenv lock #{ self.class::NAME }` Command"
        
        parser.banner = [
          title + "\n" + ("=" * title.length),
          self.class::DESCRIPTION,
          "Usage:",
          "  #{ self.class::USAGE }",
        ].join "\n\n"
        parser.separator ""
        
        unless self.class::ALIASES.empty?
          parser.separator "Aliases: #{ self.class::ALIASES.join( ', ' )}"
          parser.separator ""
        end
        
        parser.separator "Options:"
        parser.separator ""
        
        self.class::OPTIONS.each do |name, config|
          if config[-1].is_a? Proc
            transformer = config[-1]
            setter = ->( value ) {
              options[name] = transformer.call value
            }
            config = config[0..-2]
          else
            setter = ->( value ) { options[name] = value}
          end
          
          parser.on *config, " ", &setter
        end
        
        parser.on(
          '-q', '--quiet',
          "Be quiet - don't write messages to STDERR (help, errors",
          "warnings, etc.). ",
          " ",
          "Non-empty RBENV_LOCK_QUIET does the same thing,",
          "but takes effect immediately at program start instead of after",
          "options are parsed.",
          " ",
        ) do
          RbenvLock::Env[:quiet] = 1
        end
        
        parser.on(
          '-d', '--debug',
          "Enable debug output (to STDERR).",
          " ",
          "Non-empty RBENV_LOCK_DEBUG does the same thing,",
          "but takes effect immediately at program start instead of after",
          "options are parsed.",
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
        
        unless self.class.examples.empty?
          parser.separator ""
          parser.separator "Examples:"
          parser.separator ""
          parser.separator self.class.examples_string
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
