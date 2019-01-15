##############################################################################
# rbenv-lock Lock File Execution Entry Point
# ============================================================================
#
# The `//bin/rbenv-lock-exec-file` binary produced from this file is used as the
# "shebang" target for lock executables, like:
#
#     #!/usr/bin/env /Users/nrser/.rbenv/plugins/rbenv-lock/bin/rbenv-lock-exec-file
#     ---
#     # YAML contents...
#
# Lock files are just executable YAML files, and running them goes here, where I
# load up a {Rbenv::Lock::Exe} from the file and `exec` it's
# {Rbenv::Lock::Exe#target_path}, replacing the process with the desired
# program.
#
# NOTE  This redirection approach seems to add about 30-40ms overhead on my box
#       (compiled with `--release`), which is ain't bad considering just getitng
#       a `puts` out of a Crystal binary seems to cost ~20ms for me, and is
#       **much** nicer than the 200ms or so I was spending going through the
#       system Ruby.
#
##############################################################################

require "./nrser/log"
require "./rbenv/**"

# The path to the lock YAML file
path = ARGV[ 0 ]

# Whatever arguments were passed to the lock
args = ARGV[ 1..-1 ]

# Load the lock up from the file
lock = Rbenv::Lock::Exe.load path

# And swap out for the target, passing it the args
lock.exec_target args
