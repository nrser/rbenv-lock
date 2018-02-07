# frozen_string_literal: true

# Requirements
# =======================================================================

# Project / Package
# -----------------------------------------------------------------------
require_relative './cmd/help'
require_relative './cmd/create'
require_relative './cmd/list'


# @todo document RbenvLock::Cmd module.
module RbenvLock::Cmd
  
  def self.all
    [
      RbenvLock::Cmd::Create,
      RbenvLock::Cmd::List,
      RbenvLock::Cmd::Help,
    ]
  end
  
  
  def self.each &block
    all.each &block
  end
  
end # module RbenvLock::Cmd
