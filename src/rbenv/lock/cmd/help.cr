# Requirements
# =======================================================================

# Project / Package
# -----------------------------------------------------------------------
require "./base"
require "../exe"


# Namespace
# =======================================================================

module Rbenv
module Lock
module Cmd

# Definitions
# =======================================================================

# Help locks.
# 
class Help < Base
  
  def self.plugin_usage : String
    "Usage: rbenv lock " +
      Cmd.all.map {|c| c.canonical_name }.to_a.sort.join( "|" ) +
      " [-h|--help] ..."
  end
  
  # @@aliases = [ "-h", "--help" ]
  
  @@description = \
    "Get help on `rbenv lock` in general or about a specific command."
  
  @@usage = "rbenv lock help [COMMAND]"
  
  property? usage : Bool = false
  
  def print_plugin_help!( io : IO = @out_io )
    io.puts <<-END
`rbenv lock` Command
====================

Mange "locks" - small executable scripts (like shims) placed in

    #{ Rbenv::Lock::Exe.dir }/<BIN>

that *always* run BIN using a specific Ruby version, with optional gemset[1]
for full isolation.

  [1] Gemsets require `rbenv-gemset` plugin, available separately.
      See https://github.com/jf/rbenv-gemset for details.

When the locks directory precedes the `rbenv` shims directory in the system
PATH the lock script will be run instead of the shim, causing the target
to run using that Ruby version regardless of what Ruby version is active
with `rbenv`.

Commands:
END
  
    Cmd.all.each do |cmd_class|
      io.puts "  #{ cmd_class.usage }"
      io.puts "    #{ cmd_class.description }"
      io.puts
    end
    
    io.flush
  end
  
  protected def init_options( parser ) : Nil
    # Define `--usage` ourselves, so Base skips it, 'cause it causes an early
    # termination at parsing.
    parser.on(
      "--usage",
      "Print usage and exit.",
    ) { @usage = true }
  end
  
  def on_run : ExitStatus
    args = @args
    
    case
    when args.empty? && !usage?
      # With no args **and** no usage **always** prints plugin help. Any of
      # these:
      # 
      # 1.  `$ rbenv lock               # => name_arg=nil, args=[]`
      # 2.  `$ rbenv lock [-h|--help]   # => name_arg=<flag>, args=[]`
      # 3.  `$ rbenv lock help          # => name_arg="help", args=[]`
      # 
      print_plugin_help!
      # However, *success* depends on *how* it happen:
      # 
      # 1.  `$ rbenv lock               # => FAIL
      # 2.  `$ rbenv lock [-h|--help]   # => OK
      # 3.  `$ rbenv lock help          # => OK
      # 
      # Basically, `rbenv lock` is an error, since used in another program it
      # almost certainly indicates a typo or misunderstanding rather than 
      # trying to print the plugin help.
      # 
      (name_arg.nil? ? ExitStatus::FAIL : ExitStatus::OK)
      
    when args.empty? && usage? && name_arg.nil?
      # This case, which is OK to get plugin usage
      # 
      #     $ rbenv lock --usage
      # 
      out! self.class.plugin_usage
      ExitStatus::OK
      
    when args.empty? && usage? && !name_arg.nil?
      # This case, which is OK to get help command usage
      # 
      #     $ rbenv lock [-h|--help|help] --usage
      # 
      out! self.class.usage
      ExitStatus::OK
      
    else
      # We have a command to delegate to, like:
      # 
      #     $ rbenv lock help [--usage] add
      # 
      # which "re-writes" to
      # 
      #     $ rbenv lock add --usage|--help
      # 
      # *except* with
      # 
      #     $ rbenv lock help --usage -h|--help
      # 
      Cmd.find!( args[ 0 ] )
        .new( args[ 0 ], [ usage? ? "--usage" : "--help" ], out_io, err_io )
        .run!
    end
  end
  
end # class Help



# /Namespace
# =======================================================================

end # module Cmd
end # module Lock
end # module Rbenv
