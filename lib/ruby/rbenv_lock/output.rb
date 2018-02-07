# frozen_string_literal: true

# Requirements
# =======================================================================
require 'pp'


# Declarations
# =======================================================================

module RbenvLock; end


# Definitions
# =======================================================================


# Handle output as a mixin
module RbenvLock::Output
  
  def self.included base
    base.extend ClassMethods
    
    ClassMethods.instance_methods.each do |name|
      base.send :define_method, name do |*args|
        self.class.public_send name, *args
      end
    end
  end
  
  module ClassMethods
    
    def debug?
      ! RbenvLock::Env[:debug].to_s.empty?
    end
    

    def quiet?
      ! RbenvLock::Env[:quiet].to_s.empty?
    end
    
    
    def puts_to io, *args
      if args[-1].is_a? Hash
        msgs = args[0..-2]
        values = args[-1]
      else
        msgs = args
        values = {}
      end
      
      output = msgs.join ' '
      
      unless values.empty?
        values.each { |name, value|
          dump = value.pretty_inspect.chomp
          
          lines = dump.lines
          
          if lines.length > 1
            dump = "\n" + lines.map { |line|
              "    " + line
            }.join
          end
        
          output += "\n  #{ name }: #{ dump }"
        }
      end
      
      io.puts output
    end


    def err *args
      return if quiet?
      puts_to $stderr, *args
    end


    def out *args
      puts_to $stdout, *args
    end


    def debug *args
      return unless debug?
      err "DEBUG [rbenv-lock]", *args
    end
    
    
    def info *args
      err *args
    end
    
    
    def warn *args
      err "WARN  [rbenv-lock]", *args
    end
    
    
    def error *args
      err "ERROR [rbenv-lock]", *args
    end


    def fatal *args
      options = { exit: 1 }
      
      if args[-1].is_a? Hash
        options.merge! args[-1]
        args = args[0..-2]
      end
      
      error *args
      
      if options[:help]
        err
        err options[:help]
      end
      
      exit options[:exit]
    end
  end
  
end # module RbenvLock
