# Namespace
# =======================================================================

module Rbenv
module Lock


# Definitions
# =======================================================================

# Base class for application-secific `Exception`.
# 
class Error < Exception
  
  def initialize( *message : _, **values : _ )
    super( NRSER::Reason.format *message, **values )
  end
  
  def initialize( message : String )
    super( message )
  end
  
end


class Error::User < Error
end


class Error::User::Argument < Error::User
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
class Error::Internal::State < Error::Internal
end


class Error::External < Error
end


class Error::External::Process < Error::External
end


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
