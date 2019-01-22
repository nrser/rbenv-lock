# Requirements
# ============================================================================

### Stdlib ###

### Deps ###

### Project / Package ###

require "./base"
require "../exe"


# Namespace
# =======================================================================

module Rbenv
module Lock
module Cmd

# Definitions
# =======================================================================

# Create a lock (or overwrite one with `--force`)
# 
class Add < Base
  
  @@description = "Add a lock (or overwrite one with `--force`)."
  
  @@usage = "rbenv lock add RUBY_VERSION EXE_NAME [OPTIONS]"
  
  @@examples = [
    {
      name: %{1. Basic Usage},
      body: \
        %{Lock the `qb` bin to Ruby 2.3.6\n} \
        %{    rbenv lock add 2.3.6 qb\n} \
        %{\n}
    },
    
    {
      name: %{2.  "Full" example},
      body: \
        %{Isolate the `qb` bin from the gem of the same name in a gemset (also of\n} \
        %{the same name).\n} \
        %{\n} \
        %{Requires the `rbenv-gemset` plugin.\n} \
        %{\n} \
        %{Gemset will be created if it doesn't exist, and gem will be installed in\n} \
        %{if it isn't present.\n} \
        %{\n} \
        %{    rbenv lock add 2.3.6 qb --gem=qb --gemset=qb\n} \
        %{\n}
    },
    
    {
      name: %{3.  "Full" example with inferred gem and gemset names},
      body: \
        %{Since often times the gem and executable names are the same and that name\n} \
        %{is a natural choice for an isolating gemset name the `gem` and `gemset`\n} \
        %{values can be inferred:\n} \
        %{\n} \
        %{    rbenv lock add 2.3.6 qb --gem --gemset\n} \
        %{\n} \
        %{Exactly the same result as example (2).\n} 
    },
  ]
  
  getter? force : Bool = false
  
  getter? bin_only : Bool = false
  
  getter gemset : Nil | String = nil
  
  getter? implicit_gemset : Bool = false
  
  getter gem : Nil | String = nil
  
  getter? implicit_gem : Bool = false
  
  getter? direct : Bool = false
  
  
  protected def init_options( parser ) : Nil
    
    parser.on(
      "-s", "--gemset",
      %{Implicit version of `--gem=GEMSET` option - the *gem name* will\n} \
      %{be used as the name of the gemset.}
    ) { @implicit_gemset = true }
    
    parser.on(
      "--gemset=GEMSET",
      %{Use an gemset via the `rbenv-gemset` plugin (must be installed).\n} \
      %{ \n} \
      %{Allows isolation of the locked bin's gem and it's dependencies.\n} \
      %{ \n} \
      %{If the gemset doesn't exist it will be created.}
    ) { |gemset| @gemset = gemset }
    
    parser.on(
      "-g", "--gem",
      %{Implicit version of `--gem=NAME@VERSION` - the *executable* name will\n} \
      %{be used as the name of the gem.}
    ) { @implicit_gem = true }
    
    parser.on(
      "--gem=NAME@VERSION",
      %{Associate lock with a gem.\n} \
      %{ \n} \
      %{When provided, the gem will be installed if it's not present\n} \
      %{(unless the `--bin-only` option is provided as well).\n} \
      %{ \n} \
      %{A gem version may added like `--gem=qb@0.3.0` to install a specific\n} \
      %{gem version, otherwise it just uses `gem install NAME`.\n} \
      %{ \n} \
      %{If NAME is omitted, the gem name is assumed to be the same as the BIN.\n} \
      %{ \n} \
      %{You can use something like `--gem=@0.3.0` to provide a gem version\n} \
      %{and assume the gem name is BIN.}
    ) { |gem| @gem = gem }
    
    parser.on(
      "--bin-only",
      %{Just write the lock bin file, don't create gemsets, install gems, etc.}
    ) { @bin_only = true }
    
    parser.on(
      "-f", "--force",
      %{Overwrite lock file if exists}
    ) { @force = true }
    
    parser.on(
      "--direct",
      %{Bypass rbenv completely and directly execute the target executable.\n} \
      %{ \n} \
      %{WARNING: This is considerably faster, but does not completely emulate\n} \
      %{rbenv and rbenv-gemset behavior, and ignores any other plugins\n} \
      %{completely.\n}
    ) { @direct = true }
  end
  
  
  def on_run
    if args.size < 2
      raise Error::User::Argument.new \
        "Too FEW arguments (expected 2, found #{ args.size })"
    elsif args.size > 2
      raise Error::User::Argument.new \
        "Too MANY arguments (expected 2, found #{ args.size })"
    end
    
    version = Lock.rbenv.version_for args[0]
    name = args[1]
    
    # If we didn't receive a `--gem=GEM` but *did* receive just `--gem` then
    # we want to use the exe name as the `#gem`
    if implicit_gem? && self.gem.nil?
      @gem = name
    end
    
    # `#gem` can tpyically be in formats:
    # 
    # 1.  GEM_NAME
    # 2.  GEM_NAME@GEM_VERSION
    # 3.  @GEM_VERSION, with an implicit `gem_name = exe_name`
    # 
    if gem = self.gem
      # Guard to let the type system know it ain't `nil` in here
      
      gem_name, gem_version = if gem.starts_with? '@'
        # If it's something like `--gem=@0.1.0` then we assume the gem name
        # and `Exe` name to be the same.
        { name, gem[ 1..-1 ] }
        
      elsif gem.includes? '@'
        split = gem.split '@', 2
        { split[0], split[1] }
      else
        { gem, nil }
      end
      
    end # gem parsing
    
        
    if implicit_gemset? && gemset.nil?
      @gemset = gem_name
    end
    
    debug "Running `create` cmd, parsed args:",
      name: name,
      ruby_version: version,
      target: name,
      gemset: gemset,
      gem_name: gem_name,
      gem_version: gem_version,
      direct: self.direct?
      
    
    lock = Rbenv::Lock::Exe.new \
      name: name,
      ruby_version: version,
      target: name,
      gemset: gemset,
      gem_name: gem_name,
      gem_version: gem_version,
      direct: self.direct?
    
    lock.create force: self.force?, bin_only: self.bin_only?
    ExitStatus::OK
  end # #on_run
  
end # class Add


# /Namespace
# =======================================================================

end # module Cmd
end # module Lock
end # module Rbenv
