require "./rbenv_lock"
require "./rbenv_lock/lock"

path = ARGV[ 0 ]
args = ARGV[ 1..-1 ]

lock = RbenvLock::Lock.load path

lock.exec_target args
