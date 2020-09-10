require "option_parser"

class OptionParser
  
  # How many spaces "long" (`#size >= 33`) descriptions are indented by in the
  # help (`#to_s`) string.
  # 
  # <https://github.com/crystal-lang/crystal/blob/0.35.1/src/option_parser.cr#L280>
  # 
  DESCRIPTION_INDENT = 37
  
  def self.join_lines( lines : Enumerable(String) ) : String
    lines.join( "\n#{ " " * DESCRIPTION_INDENT }" )
  end
  
  
  # Accept a splat of `String` lines as the description.
  # 
  def on( short_flag : String,
          long_flag : String,
          *description_lines : String,
          &block : String -> )
    on  short_flag,
        long_flag,
        self.class.join_lines( description_lines ),
        &block
  end # #on
  
  def on(
    flag : String,
    *description_lines : String,
    &block : String ->
  )
    on flag, self.class.join_lines( description_lines ), &block
  end # #on
  
  def add(
    short_flag : String,
    long_flag : String,
    description : String,
    &block : String ->
  ) : Void
    has_short_flag = @handlers[ parse_flag_definition( short_flag )[0] ]?
    has_long_flag = @handlers[ parse_flag_definition( long_flag )[0] ]?
    
    case
    when has_short_flag && has_long_flag
      # pass
    when has_short_flag && !has_long_flag
      on( long_flag, description, &block )
    when !has_short_flag && has_long_flag
      on( short_flag, description, &block )
    else
      on short_flag, long_flag, description, &block
    end
  end
  
  def add(
    short_flag : String,
    long_flag : String,
    *description_lines : String,
    &block : String ->
  ) : Void
    add short_flag,
        long_flag,
        self.class.join_lines( description_lines ),
        &block
  end
  
  def add(
    flag : String,
    description : String,
    &block : String ->
  ) : Void
    unless @handlers[ parse_flag_definition( flag )[0] ]?
      on flag, description, &block
    end
  end
  
  def add(
    flag : String,
    *description_lines : String,
    &block : String ->
  ) : Void
    add flag, self.class.join_lines( description_lines ), &block
  end
  
end # class OptionParser
