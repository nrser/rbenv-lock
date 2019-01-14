# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# I guess some old Rubies need this
require 'rubygems'

# Project / Package
# -----------------------------------------------------------------------

require_relative './output'


# Namespace
# =======================================================================

module  RbenvLock


# Definitions
# =======================================================================

# @todo document Rbenv class.
class Rbenv

  include Output
  
  
  # Construction
  # ========================================================================
  
  def initialize
    @prefixes = {}
  end
  
  
  # Instance Methods
  # ========================================================================
  
  def run cmd, *args
    args_string = args.shelljoin
    shell_string =  "rbenv-#{ cmd } #{ args_string } 2>/dev/null " +
                    "|| rbenv #{ cmd } #{ args_string }"
    measure -> {[
      cmd.to_s,
      {
        class: self.class,
        method: __method__,
        cmd: cmd,
        shell_string: shell_string,
      }
    ]} do
      `#{ shell_string }`
    end
  end
  
  
  # Absolute path to 
  # 
  def root
    @root ||= ENV['RBENV_ROOT'] || run( :root ).chomp
  end
  
  
  # Bare names of Ruby versions installed via rbenv.
  # 
  # @example
  #   RbenvLock::Rbenv.new.versions
  #   #=> ["2.0.0-p353", "2.3.7", "2.4.4", "2.5.1"]
  # 
  # @return [Array<String>]
  # 
  def versions
    @versions ||= run( :versions, '--bare' ).lines.map( &:chomp )
  end
  
  
  # Map of rbenv's Ruby versions (which are {String}s) to a {Gem::Version}
  # instance of them, taking account of the `-pXXX` format for `2.0.0` versions.
  # 
  # Used for resolving requirement strings like '~> 2.3.7' to an appropriate
  # installed version (see {.ruby_version_for}).
  # 
  # @return [Hash<String, Gem::Version>]
  # 
  def version_objects
    @version_objects ||= \
      versions.
        map { |string|
          [ string, Gem::Version.new( string.gsub( /\-p(\d+)/, '.\1' ) ) ]
        }.
        to_h
  end # #version_objects
  
  
  def prefix version
    @prefixes[ version ] ||= run( :prefix, version ).chomp
  end
  
  
  def global
    @rbenv_global ||= run( :global ).chomp
  end
  
  
  def current
    @current ||= run( :'version-name' ).chomp
  end
  
  
  def shims_dir
    @shim_dir ||= File.join rbenv.root, 'shims'
  end
  
  
  def shim_path bin
    File.join shims_dir, bin
  end
  
end # class Rbenv


# /Namespace
# =======================================================================

end # module RbenvLock
