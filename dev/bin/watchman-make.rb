#!/usr/bin/env ruby

require 'shellwords'

class String
  def esc; shellescape; end
end

ROOT = File.expand_path '../..', __dir__

Dir.chdir ROOT do
  cmd = [
    'watchman-make',
    '-p', 'src/**/*.cr',
    'Makefile*',
    '-t', 'all',
  ]
  
  system *cmd
end