# Requirements
# =======================================================================

### Stdlib ###

### Deps ###

### Project / Package ###


# Namespace
# =======================================================================


module Rbenv
module Lock


# Definitions
# =======================================================================

# Base class for application-secific `Exception`.
# 
class Error < Exception
end


# Something went wrong that *should not* have ever gone wrong.
# 
class Error::Internal < Error
  def initialize( message = "Unknown error. Yeah, that bad / lazy :(" )
    super( message )
  end
end


# Yes, we have shotty ad-hoc internal state. Yes, we're ashamed of it.
# 
class Error::Internal::State < Error
end


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
