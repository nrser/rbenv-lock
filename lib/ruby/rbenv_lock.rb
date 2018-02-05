require 'pathname'
require 'pp'
require 'optparse'
require 'shellwords'
require 'fileutils'

class Object
  def quote
    to_s.shellescape
  end
end

module RbenvLock
  
  # Constants
  # ============================================================================
  
  module Env
    VAR_PREFIX = 'RBENV_LOCK'
    
    def self.var_name key
      "#{ VAR_PREFIX }_#{ key.to_s.upcase }"
    end
    
    def self.[] key
      ENV[ var_name( key ) ]
    end
    
    def self.[]= key, value
      ENV[ var_name( key ) ] = value.to_s
    end
  end
  
  
  # Module Methods
  # ============================================================================
  
  def self.debug?
    !! Env[:debug]
  end
  
  
  def self.puts_to fp, *args
    if args[-1].is_a? Hash
      msgs = args[0..-2]
      values = args[-1]
    else
      msgs = args
      values = {}
    end
    
    output = msgs.join ' '
    values.each { |name, value|
      output += "\n  #{ name }: #{ value.inspect }"
    }
    fp.puts output
  end
  
  
  def self.err *args
    puts_to $stderr, *args
  end
  
  
  def self.out *args
    puts_to $stdout, *args
  end
  
  
  def self.debug *args
    return unless debug?
    err "DEBUG [rbenv-lock]", *args
  end
  
  
  def self.fatal *args
    options = { exit: 1 }
    
    if args[-1].is_a? Hash
      options.merge! args[-1]
      args = args[0..-2]
    end
    
    err "ERROR", *args
    
    if options[:help]
      err
      err options[:help]
    end
    
    exit options[:exit]
  end
  
  
  def self.locks_dir
    @locks_dir ||= Pathname.new(
      Env[:locks_dir] ||
      File.join( `rbenv-root 2>/dev/null`.chomp, 'locks' )
    ).expand_path
  end
  
  
  def self.lock_abs_paths
    debug "locks_dir", locks_dir: locks_dir
    
    return [] unless locks_dir.directory?
    
    locks_dir.entries.
      reject { |path| path.to_s == '.' || path.to_s == '..' }.
      map { |path| locks_dir + path }.
      select( &:executable? )
  end
  
  
  def self.rbenv_root
    @rbenv_root ||= ENV['RBENV_ROOT'] || `rbenv-root`.chomp
  end
  
  
  def self.rbenv_versions
    @rbenv_versions ||= `rbenv-versions --bare 2>/dev/null`.
      lines.
      map( &:chomp )
  end
  
  
  def self.rbenv_current
    @rbenv_current ||= `rbenv-version-name`.chomp
  end
  
  
  def self.rbenv_global
    @rbenv_global ||= `rbenv-global`.chomp
  end
  
  
  def self.shim_dir
    @shim_dir ||= File.join rbenv_root, 'shims'
  end
  
  
  def self.shim_for bin
    File.join shim_dir, bin
  end
  
  
  def self.rbenv_version_for input
    # Exact match, just return it
    return input if rbenv_versions.include? input
    
    # Alias for the current version
    return rbenv_current if input == 'current'
    
    # Alias for the global version
    return rbenv_global if input == 'global'
    
    # If we prefix match a *single* version, use that
    matches = rbenv_versions.select { |version| version.start_with? input }
    return matches[0] if matches.length == 1
    
    # We got nada
    err "ERROR Can't find Ruby version #{ input.inspect }"
    err
    err "Available versions:"
    err
    rbenv_versions.each { |version| err "- #{ version }" }
    err
    err "Available aliases:"
    err
    err "  current -> #{ rbenv_current }"
    err "  global  -> #{ rbenv_global }"
    err
    exit 1
  end
  
  
  def self.rbenv_prefix version
    @rbenv_prefixes ||= {}
    @rbenv_prefixes[version] ||= `rbenv-prefix #{ version.shellescape }`.chomp
  end
  
  
  def self.add_common_options parser
    parser.on(
      '-d',
      '--debug',
      "Enable debug output (to STDERR)"
    ) do
      Env[:debug] = 1
    end
  end
  
  
  def self.run_in_lock_env cmd, version, gemset = nil
    cmd = "RBENV_VERSION='#{ version }' " + cmd
    
    if gemset
      cmd = "RBENV_GEMSETS='#{ gemset }'" + cmd
    end
    
    out = `#{ cmd }`
    
    if $? == 0
      out
    else
      false
    end
  end
  
  
  def self.help_cmd
    puts "HELP!"
  end
  
  
  def self.list_cmd args, options = {}
    debug "RUNNING `list` command...", args: args
    lock_abs_paths.each { |path| puts path }
  end
  
  
  def self.create_cmd args, options = {}
    options = {force: false}.merge options
    
    parser = OptionParser.new do |parser|
      parser.banner = "Usage:\n\n  rbenv lock create VERSION BIN [OPTIONS]"
      
      parser.separator ""
      parser.separator "Options:"
      
      parser.on(
        "-s",
        "--gemset[=GEMSET]",
        "Create or use existing gemset (req. `rbenv-gemset` plugin)"
      ) do |gemset|
        options[:gemset] = gemset || true
      end
      
      parser.on(
        '-g NAME[@VERSION]',
        '--gem=NAME[@VERSION]',
        "Associate to a gem so it can be installed, updated, etc."
      ) do |gem|
        options[:gem] = gem
      end
      
      parser.on "-f", "--force",
              "Overwrite lock file if exists" do |value|
        options[:force] = value
      end
      
      parser.on "-h", "--help", "Show this message" do
        err parser.to_s
        exit 1
      end
      
      add_common_options parser
    end
    
    parser.parse! args
    
    if args.length < 2
      fatal "Too few arguments", help: parser.to_s
    elsif args.length > 2
      fatal "Too many arguments", help: parser.to_s
    end
    
    version = self.rbenv_version_for args[0]
    bin = args[1]
    
    # Use the bin name for the gemset if one wasn't provided
    options[:gemset] = bin if options[:gemset] == true
    
    debug "Running `create` cmd, parsed args:",
      version: version,
      bin: bin,
      options: options
      
    # Parse gem option if present
    if options[:gem]
      if options[:gem].include? '@'
        split = options[:gem].split '@', 2
        gem_name = split[0]
        gem_version = split[1]
      else
        gem_name = options[:gem]
        gem_version = nil
      end
    else
      gem_name = nil
      gem_version = nil
    end
    
    lock = RbenvLock::Lock.new \
      bin,
      version,
      gemset: options[:gemset],
      gem_name: gem_name,
      gem_version: gem_version
    
    lock.create force: options[:force]
    
  end
  
  
  def self.run cmd, *args
    debug "Starting run...", cmd: cmd, args: args
    
    case cmd
    when 'help', '-h', '--help'
      help_cmd args
    when 'list', 'ls'
      list_cmd args
    when 'create'
      create_cmd args
    else
      raise "Bad command: #{ cmd.inspect }"
    end
  end
  
end

require_relative './rbenv_lock/lock'
