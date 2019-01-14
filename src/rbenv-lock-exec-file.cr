require "./rbenv/**"

path = ARGV[ 0 ]
args = ARGV[ 1..-1 ]

lock = Rbenv::Lock::Exe.load path

lock.exec_target args
