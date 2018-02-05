# frozen_string_literal: true

# Requirements
# =======================================================================
require 'yaml'
require 'open3'


# Definitions
# =======================================================================

# @todo document RbenvLock::Lock class.
class RbenvLock::Lock
  
  # Constants
  # ======================================================================
  
  
  # Class Methods
  # ======================================================================
  
  
  # Attributes
  # ======================================================================
  
  attr_reader :bin, :ruby_version, :gemset, :gem_name, :gem_version
  
  
  # Constructor
  # ======================================================================
  
  # Instantiate a new `RbenvLock::Lock`.
  def initialize bin, ruby_version, options = {}
    @bin = bin
    @ruby_version = ruby_version
    @gemset = options[:gemset]
    @gem_name = options[:gem_name]
    @gem_version = options[:gem_version]
    @direct = false
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================
  
  # Are we using the risky but maybe much faster "direct" execution???
  def direct?
    @direct
  end
  
  
  # The path to the lock file
  def path
    @path ||= File.join RbenvLock.locks_dir, bin
  end
  
  
  def gemset?
    !!gemset
  end
  
  
  def gem?
    !!gem_name
  end
  
  
  def gemset_root
    return nil unless gemset
    
    @gemset_root ||= File.join \
      RbenvLock.rbenv_prefix( ruby_version ),
      'gemsets',
      gemset
  end
  
  
  def gemset_bin_dir
    File.join gemset_root, 'bin'
  end
  
  
  def version_bin_dir
    cache :@version_bin_dir do
      File.join RbenvLock.rbenv_prefix( ruby_version ), 'bin'
    end
  end
  
  
  def direct_version_bin_for bin
    File.join version_bin_dir, bin
  end
  
  
  def direct_gemset_bin_for bin
    File.join gemset_bin_dir, bin
  end
  
  
  # Get the path to a bin.
  def which bin
    if direct?
      direct_version_bin = direct_version_bin_for bin
      
      # We're going to direct to the executable, so need to figure out if it's
      # in a gemset
      if gemset?
        direct_gemset_bin = direct_gemset_bin_for bin
        
        if bin == self.bin
          # The lock bin will def be in the gemset
          direct_gemset_bin
          
        elsif ['gem', 'ruby'].include?( bin ) &&
          # These should always be in Ruby version (they come with it)
          direct_version_bin
          
        elsif File.exists?( direct_version_bin )
          # Ok, had to check... it is in the gemset
          direct_gemset_bin
        
        else
          # It's gotta be in the Ruby version
          direct_version_bin
        end
      else
        direct_version_bin
      end
    else
      # No direct, go to the shim
      RbenvLock.shim_for bin
    end
  end
  
  
  def target
    @target ||= which self.bin
  end
  
  
  def gemdir
    @gemdir ||= `#{ which( 'gem' ).quote } env gemdir`.chomp
  end
  
  
  # Clean up the path for use in {#capture}.
  # 
  # Any existing `.rbenv/versions/...` paths need to be removed from the
  # `PATH`... I'm not sure exactly why but they cause problems.
  # 
  # @return [String]
  # 
  def clean_PATH
    ENV['PATH'].split( ':' ).reject { |path|
      path.include?( File.join( RbenvLock.rbenv_root, 'versions' ) ) ||
        File.fnmatch?( '/**/rbenv/**/libexec', path )
    }.join ':'
  end
  
  
  # @return [Hash<String, String>]
  #   The ENV vars the lock needs to work.
  # 
  def env
    lock_env = {
      'RBENV_VERSION' => ruby_version,
    }
    
    # `direct` sets things up to call *directly to the real bin, bypassing
    # `rbenv` entirely*. This might have serious speed advantages, but also
    # seems likely to be riddled with issues and brittle with regards to
    # future changes... but I made it work, so I'm going to leave the code in
    # here as an option.
    if direct?
      lock_env.merge!({
        # Prefix the (clean) path with the bin dir for the Ruby version, like
        # 
        # version 2.3.6 =>
        #   "/Users/nrser/.rbenv/versions/2.3.6/bin:<clean-path>"
        # 
        'PATH' => "#{ version_bin_dir }:#{ clean_PATH }",
      })
    end
    
    if gemset?
      lock_env.merge!({
        'RBENV_GEMSETS' => gemset,
      })
      
      # See notes above
      if direct?
        lock_env.merge!({
          'GEM_HOME'  => gemset_root,
          'GEM_PATH'  => "#{ gemset_root }:#{ gemdir }",
          'PATH'      => "#{ gemset_bin_dir }:#{ lock_env['PATH'] }",
        })
      end
    end
    
    if gem?
      # This is really just for persistence
      lock_env['RBENV_LOCK_GEM'] = gem_name
      # I don't think we need the version? It's just for installing?
    end
    
    lock_env
  end
  
  
  # @return [nil]
  #   One of
  #   
  #   1.  {#gem_name} is `nil`
  #   2.  {#gem_name} gem is not installed in the lock "environment"
  #       (the Ruby version and optional gemset).
  #   
  # @return [Gem::Specification]
  #   If we have a {#gem_name} and it's installed in the lock "environment"
  #   (the Ruby version and optional gemset).
  # 
  def gem_spec
    return nil unless gem?
    
    cache :@gem_spec do
      out, err, status = capture(
        which( 'gem' ),
        'specification',
        '--local',
        gem_name
      )
      
      if status == 0
        YAML.load out
      else
        nil
      end
    end
  end
  
  
  # Run a {Open3.capture3} in the lock's "environment".
  # 
  # Same exact args except we will always add an `env` with {#env} plus
  # {#clean_PATH}. If an `env` hash is provided, it will be merged over
  # those.
  # 
  # @see http://ruby-doc.org/stdlib-2.0.0/libdoc/open3/rdoc/Open3.html#method-c-capture3
  # 
  # @return [(String, String, Process::Status)]
  #   Stdout, stderr, exit status for the subprocess.
  # 
  def capture *args
    env, args, opts = prep_for_spawn args
    
    Open3.capture3 env, *args, opts
  end
  
  
  # @return [Process::Status]
  # 
  def stream *args
    # Ugh, I can't believe I'm writing this again... how is this not just built
    # in..?
    env, args, opts = prep_for_spawn args
    
    RbenvLock.debug "streaming...",
      env: env,
      args: args,
      opts: opts
    
    pid = Process.spawn env, *args, opts
    
    Process.wait pid
    return $?
  end
  
  
  def ensure_gemset
    if gemset?
      FileUtils.mkdir_p( gemset_root ) unless File.directory?( gemset_root )
    end
  end
  
  
  def ensure_gem
    # If the gem is not installed or isn't the right version...
    if  gem_spec.nil? ||
        ( gem_version &&
          gem_spec.version.to_s != gem_version )
      # We need to install the gem
      cmd = [
        which( 'gem' ),
        'install',
        gem_name,
      ]
      
      # Specify the version if we have one
      if gem_version
        cmd << '--version'
        cmd << gem_version
      end
      
      RbenvLock.out "Installing gem #{ gem_name }...",
        cmd: cmd
      
      stream *cmd
      
      RbenvLock.out "Installed gem #{ gem_name }"
    end
  end
  
  
  def write options = {}
    unless options[:bin_only]
      ensure_gemset if gemset?
      ensure_gem if gem?
    end
    
    File.open path, 'w' do |file|
      file.puts "#!/usr/bin/env bash"
      file.puts
      env.each { |name, value|
        file.puts "export #{ name }='#{ value }'"
      }
      file.puts
      file.puts %{exec #{ target.quote } "$@"}
      file.puts
    end
    
    FileUtils.chmod 0755, path
  end
  
  
  def create options = {}
    if  options[:force] ||
        !File.exists?( path )
      write
    else
      raise "Lock file exists: #{ path }, use --force to overwrite"
    end
  end
  
  
  protected
  # ========================================================================
    
    # Cache results in an instance variable, never re-running even if the
    # cache value is `nil` / `false` (which `||=` wont work with).
    # 
    # @param [Symbol] name
    #   Instance var name, with `@` like `:@my_var`
    # 
    # @param [Proc] &block
    #   Block to compute value if never been set.
    # 
    # @return
    #   Block / instance variable value.
    # 
    def cache name, &block
      unless instance_variable_defined? name
        instance_variable_set name, block.call
      end
      instance_variable_get name
    end
    
    
    def prep_for_spawn args
      # Get the usual env vars and add a clean PATH
      env = self.env
      
      unless direct?
        env.merge! 'PATH' => clean_PATH
      end
      
      # If we were passed an `env` hash as the first argument merge it into
      # our env.
      if args[0].is_a? Hash
        env.merge! args[0]
        args = args[1..-1]
      end
      
      # Default options; need to clear out the ENV so that any rbenv-ness that
      # is existing in this process doesn't muck up the sub-processes
      opts = {unsetenv_others: true}
      
      if args[-1].is_a? Hash
        opts.merge! args[-1]
        args = args[0..-2]
      end
      
      [env, args, opts]
    end
    
  # end protected
  
  
end # class RbenvLock::Lock
