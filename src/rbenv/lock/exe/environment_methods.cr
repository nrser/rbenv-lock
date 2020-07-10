##############################################################################
# `Rbenv::Lock::Exe` Envrionemnt Methods
# ============================================================================
# 
# The `//src/rbenv/lock/exe.cr` file got a bit big and unwieldy by my standards,
# so I started to split it up. It is `require`d in the main `Exe` file and
# should **NOT** be loaded independently.
# 
# This file contains methods for creating execution environments for lock 
# executables.
# 
##############################################################################

require "../core_ext/hash"

# Namespace
# =======================================================================

module Rbenv
module Lock


# Definitions
# =======================================================================

class Exe
  
  # Constants
  # ==========================================================================
  
  # `ENV` var names to filter out of "clean" environments.
  # 
  # See `#clean_ENV`.
  # 
  DIRTY_ENV_NAMES = Set{
    "GEM_HOME",
    "GEM_PATH",
    "RBENV_DIR",
    "RBENV_HOOK_PATH",
    "RBENV_VERSION",
    
    # Additional places that Ruby will search when `require`ing.
    "RUBYLIB",
  }
  
  
  # Class Methods
  # ==========================================================================
  
  # Select only interesting-looking environment variables from an *env*.
  # 
  # Used when logging environments to make it more reasonable to read.
  # 
  def self.filter_env( env )
    env.select { |name, value|
      case name
      when /\ARUBY/, /\ARBENV/, /\AGEM/
        true
      when "PATH"
        true
      else
        false
      end
    }
  end
  
  
  # Instance Methods
  # ==========================================================================
  
  # Get a copy of `ENV[ "PATH" ]` stripped of all rbenv and rbenv-gemset
  # elements:
  #
  # 1.  `Rbenv::Client#libexec_path` - rbenv's `libexec` directory, which is
  #     where the `rbenv`, `rbenv-exec`, etc. scripts live.
  #
  #     On my Mac with Homebrew installation it is:
  #
  #         /usr/local/Cellar/rbenv/1.1.1/libexec
  #
  #     This is added by the `rbenv` script every time it's run, regardless of
  #     whether it's present or not:
  #
  #     <https://github.com/rbenv/rbenv/blob/59785f6762e9325982584cdab1a4c988ed062020/libexec/rbenv#L73>
  #
  # 2.  Anything in "$(rbenv root)/versions/". This includes...
  #
  #     1.  `versions/<VERSION>/bin`, which gets stuck there by `rbenv-exec`:
  #
  #         <https://github.com/rbenv/rbenv/blob/59785f6762e9325982584cdab1a4c988ed062020/libexec/rbenv-exec#L45>
  #
  #         when running an executable installed by a Gem in that version.
  #
  #     2.  `versions/<VERSION>/gemsets/<GEMSET>/bin`, put there by
  #         `rbenv-gemset`:
  #
  #         <https://github.com/jf/rbenv-gemset/blob/6684504d684e520082a4e73382a7bb8d2c154a3b/etc/rbenv.d/exec/gemset.bash#L22>
  #         
  # 3.  Any `<P>/bin` where `P` is an entry in `GEM_PATH`, which are put there
  #     as part of the same process as (2.2), except for project-local gemset
  #     directories.
  #
  # We need these stripped paths because anything could have been happening 
  # before we got called, and we want to start clean before we either go
  # back in to a shim (which will add all it's stuff) or add the things we
  # need directly.
  #
  def clean_PATH : String
    exact = [
      Lock.rbenv.libexec_path,
    ]
    
    prefixes = [
      File.join( Lock.rbenv.root, "versions" ) + '/',
    ]
    
    if ( gem_path = ENV[ "GEM_PATH" ]? )
      gem_path.split( ':' ).each { |path| exact << File.join( path, "bin" ) }
    end
    
    ENV[ "PATH" ].
      split( ':' ).
      reject { |path|
        exact.any? { |bad_path| path == bad_path } \
        || prefixes.any? { |bad_start| path.starts_with? bad_start }
      }.
      join ':'
  end # #clean_PATH
  
  
  # Get an environment clean of all rbenv values, as well as the gem pathing
  # values `GEM_HOME` and `GEM_PATH`.
  # 
  # This is used as the starting point for the `Exe`'s execution environment 
  # `#env`.
  # 
  # We do this because we're never sure what's beeen going on before we were 
  # called, and the goal of `rbenv-lock` is to produce consistent execution
  # results regardless of where the lock executable is called from.
  # 
  # Starting with a filtered environment should help that.
  # 
  def clean_ENV : Hash(String, String)
    ENV.to_h.tap { |env|
      env.reject! { |name, value| DIRTY_ENV_NAMES.includes? name }
      
      env[ "PATH" ] = clean_PATH
    }
  end # clean_ENV
  
  
  # Get the execution environment for the `Exe`.
  # 
  # rbenv is mostly about using the correct environment, making this probably
  # the most important part of the application.
  # 
  def env( from = clean_ENV, direct = direct? ) : Hash(String, String)
    from.tap do |env|
      # Any `name => nil` in `@extra_env` means delete that name
      env.merge_and_delete_nils! @extra_env
      
      # We always want this guy set
      env[ "RBENV_VERSION" ] = ruby_version
      
      # And the root as well, in case we go strait to a libexec file
      env[ "RBENV_ROOT" ] = Lock.rbenv.root
      
      # `direct` sets things up to call *directly to the real bin, bypassing
      # `rbenv` entirely*. This might have serious speed advantages, but also
      # seems likely to be riddled with issues and brittle with regards to
      # future changes... but I made it work, so I'm going to leave the code in
      # here as an option.
      if direct
        # Prefix the `PATH` with the bin dir for the Ruby version, like:
        # 
        #     "/Users/nrser/.rbenv/versions/2.3.6/bin:#{ ENV[ "PATH" ] }"
        # 
        # We omit the paths to `Rbenv::Client#libexec_path` and the rbenv hooks,
        # since we really shouldn't need them.
        # 
        env[ "PATH" ] = \
          if (current_PATH = env[ "PATH" ]?)
            "#{ version_bin_dir }:#{ current_PATH }"
          else
            version_bin_dir
          end
      end
      
      # Are we using a gemset?
      if (
        (gemset = self.gemset?) &&
        (gemset_dir = self.gemset_dir) &&
        (gemset_bin_dir = self.gemset_bin_dir)
      )
        # Set the gemset name so that `rbenv-gemset` will do the right thing
        # when going through the shims (when not `direct?`). This shouldn't 
        # really matter when we're `direct?`, but we want to remain close to
        # that environment, so it's good to have there too.
        env[ "RBENV_GEMSETS" ] = gemset
        
        # Are we going directly?
        if direct
          # We need to do the work `rbenv-gemset` would have done...
          
          # Set `GEM_HOME` to the gemset's root, so that gems install there.
          env[ "GEM_HOME" ] = gemset_dir
          
          # We also want the gemset root at the front of the gem path.
          gem_path = gemset_dir
          
          # Unless shared gems are disabled (ENV var is absent or empty), append
          # the Ruby version's gem directory to the gem path so that gems from
          # there can be used too.
          if ENV.missing?( "RBENV_GEMSET_DISABLE_SHARED_GEMS" )
            gem_path = "#{ gem_path }:#{ ruby_version_gemdir }"
          end
          
          # Set the value
          env[ "GEM_PATH" ] = gem_path
          
          # Prepend the gemset's `bin` directory to the `PATH` so that those
          # executables take precedence.
          env[ "PATH" ] = "#{ gemset_bin_dir }:#{ env[ "PATH" ] }"
          
        end # if direct?
      end # if gemset?
      
      if (gem_name = self.gem_name?)
        # This is really just for persistence
        env[ "RBENV_LOCK_GEM" ] = gem_name
        # I don't think we need the version? It's just for installing?
      end
      
    end # clean_ENV.tap
    
  end # #env
  
  
end # class Exe


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
  