require "option_parser"

class OptionParser
  
  # How many spaces "long" (`#size >= 33`) descriptions are indented by in the
  # help (`#to_s`) string.
  # 
  # <https://github.com/crystal-lang/crystal/blob/c9d1eef8fde5c7a03a029d64c8483ed7b4f2fe86/src/option_parser.cr#L176>
  # 
  DESCRIPTION_INDENT = 37
  
  
  # Accept a splat of `String` lines as the description.
  # 
  def on( short_flag : String,
          long_flag : String,
          *description_lines : String,
          &block : String -> )
    on  short_flag,
        long_flag,
        description_lines.join( "\n#{ " " * DESCRIPTION_INDENT }" ),
        &block
  end # #on
  
end # class OptionParser
