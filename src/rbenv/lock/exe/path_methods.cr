##############################################################################
# `Rbenv::Lock::Exe` Path Methods
# ============================================================================
# 
# The `//src/rbenv/lock/exe.cr` file got a bit big and unwieldy by my standards,
# so I started to split it up. It is `require`d in the main `Exe` file and
# should **NOT** be loaded independently.
# 
# This file contains methods for obtaining the correct paths to the various
# files and directories needed to properly construct the environments and 
# execute the commends necessary.
# 
##############################################################################

# Namespace
# =======================================================================

module Rbenv
module Lock


# Definitions
# =======================================================================

class Exe
  
  # Class Methods
  # ==========================================================================
  
  # Where to put lock executables if nothing is specified in the environment
  # (see {Env}):.
  # 
  # Equivalent to `"$(rbenv root)/locks".
  # 
  def self.default_dir : String
    @@default_locks_dir ||= File.join( Rbenv::Lock.rbenv.root, "locks" )
  end
  
  
  # Absolute path to where the lock executable files go.
  #
  # Looks for `$RBENV_LOCK_LOCKS_DIR` first (via `Env`), falling back to
  # {.default_locks_dir}. Exapnds either of them to form the response.
  #
  def self.dir : String
    File.expand_path( Env[ :locks_dir ]? || default_dir )
  end
  
  
  def self.exec_file_bin_path : String
    File.join Lock.rbenv.root, "plugins", "bin", "rbenv-lock-exec-file"
  end
  
  
  # The absolute path to a executable file given its name (relative to the 
  # current {.dir}).
  # 
  def self.path_for( name ) : String
    File.join dir, name
  end
  
  
  # Instance Methods
  # ==========================================================================
  
  # Absolute path to the lock file.
  # 
  def path : String
    @path ||= self.class.path_for name
  end
  
  
  def gem_exe_path : String
    Lock.rbenv.gem_exe_path( ruby_version )
  end
  
  
  # Absolute path to the `bin` directory in the `Client#prefix` directory for
  # this `Exe`'s `#ruby_version`.
  # 
  def version_bin_dir : String
    File.join( Lock.rbenv.prefix( ruby_version ), "bin" )
  end
  
  
  # Absolute path to a bin file in `#version_bin_dir`.
  # 
  def direct_version_bin_path_for( bin ) : String
    File.join version_bin_dir, bin
  end
  
  
  # Absolute path to the gemset directory (if the `Exe` has a `#gemset`).
  #
  def gemset_dir : String?
    File.join? \
      Lock.rbenv.prefix( ruby_version ),
      "gemsets",
      gemset
  end
  
  
  # Absolute path to the `bin` directory for the `#gemset` (if the `Exe` has a
  # `#gemset`).
  #
  def gemset_bin_dir : String?
    File.join? gemset_dir, "bin"
  end
  
  
  # Absolute path to an executable in the `#gemset_bin_dir` (if the `Exe` has
  # a `#gemset`).
  # 
  def direct_gemset_bin_path_for( name ) : String?
    File.join? gemset_bin_dir, name
  end
  
  
  # Get the absolute path to the `#ruby_version`'s gems directory (where gems
  # are typically installed for that version).
  # 
  def ruby_version_gemdir : String
    @gemdir ||= begin
      clean_env = clean_ENV
      clean_env[ "RBENV_VERSION" ] = ruby_version
      
      # Based off:
      # 
      # https://github.com/crystal-lang/crystal/blob/c9d1eef8fde5c7a03a029d64c8483ed7b4f2fe86/src/process.cr#L550
      # 
      process = Process.new \
        command: Lock.rbenv.gem_exe_path( ruby_version ),
        args: [ "env", "gemdir" ],
        shell: false,
        input: Process::Redirect::Inherit,
        output: Process::Redirect::Pipe,
        error: Process::Redirect::Inherit,
        env: clean_env,
        clear_env: true
        
      output = process.output.gets_to_end
      
      status = process.wait
      $? = status
      
      output.chomp
    end
  end # #gemdir
  
  
  # Find the path to a bin file.
  # 
  # NOTE
  # 
  # This method was essentailly coppied over from the Ruby version, and I'm not
  # entirely sure why it was written like this... it seems to try to form the
  # path *without* actually seeing where files are and aren't... but besides
  # the time cost, there doesn't appear to be any other reason for that..?
  # 
  def which( bin : String ) : String
    # Not direct, go to the shim
    return Lock.rbenv.shim_path( bin ) unless direct?
    
    # We're going to direct to the executable, so need to figure out if has a
    # gemset
    if (direct_gemset_bin_path = direct_gemset_bin_path_for( bin ))
      
      if bin == name
        # The lock bin will def be in the gemset
        direct_gemset_bin_path
        
      elsif {"gem", "ruby"}.includes?( bin )
        # These should always be in Ruby version (they come with it)
        direct_version_bin_path_for bin
        
      elsif File.exists?( direct_gemset_bin_path )
        # Ok, had to check... it is in the gemset
        direct_gemset_bin_path
      
      else
        # It's gotta be in the Ruby version
        direct_version_bin_path_for bin
      end
    else
      # The lock is not in a gemset, so the bin needs to be in the version's
      # bin dir
      direct_version_bin_path_for bin
    end
  end # #which
  
  
  # Get the path for the `#target`, which will be the shim or the actual 
  # script/binary depending on if the instance is `#direct?` or not.
  # 
  def target_path : String
    @target_path ||= which target
  end
  
end # class Exe


# /Namespace
# =======================================================================

end # module Lock
end # module Rbenv
  