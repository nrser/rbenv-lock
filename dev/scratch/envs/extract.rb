require 'yaml'
require 'shellwords'

PATTERNS = [
  [ 'PATH', true ],
  [ 'RBENV_HOOK_PATH', true ],
  [ /\ARBENV_/, false ],
  [ 'RUBYLIB', true ],
  [ 'GEM_HOME', false ],
  [ 'GEM_PATH', true ],
]

# Method to extract the values we're interested in from the ENV
def extract
  array = ENV.
    map { |name, value|
      if (found = PATTERNS.find { |(pattern, is_path)| pattern === name })
        if found[ 1 ]
          [ name, value.split( ':', -1 ) + [ { 'literal' => value } ] ]
        else
          [ name, value ]
        end
      end
    }.
    compact.
    sort
  
  Hash[ array ]
end


def dump
  puts YAML.dump( extract )
end

dump if $0 == __FILE__
