# frozen_string_literal: true

# Requirements
# =======================================================================

# Project / Package
# -----------------------------------------------------------------------

# Require order becomes {RbenvLock::Cmd.all} order...
require_relative './cmd/add'
require_relative './cmd/exec'
require_relative './cmd/list'
require_relative './cmd/remove'

# Last but no least...
require_relative './cmd/help'


# @todo document RbenvLock::Cmd module.
module RbenvLock::Cmd
  
  def self.all
    RbenvLock::Cmd::Base.subclasses
  end
  
  
  def self.each &block
    all.each &block
  end
  
end # module RbenvLock::Cmd
