require "../../spec_helper"
require "rbenv/lock/run"
require "rbenv/lock/exit_status"
require "rbenv/lock/cmd"

describe Rbenv::Lock::Run do
  describe "#run" do
    run_args = ->(args : Array(String)) {
      out_io, err_io = std_ios
      run = Rbenv::Lock::Run.new args, out_io, err_io
      status = run.run
      { status, out_io, err_io }
    }
    
    describe "empty args" do
      status, out_io, err_io = run_args.call [] of String
      
      it_should_fail status
      it_should_print( "`rbenv lock` Command\n" ).at_the_start_of out_io
      it_should_print_nothing_to err_io
    end
    
    describe "plugin help" do
      %w(-h --help help).each do |help_cmd_name|
        describe "`rbenv lock #{help_cmd_name}`" do
          status, out_io, err_io = run_args.call [ help_cmd_name ]
          
          it_should_succeed status
          it_should_print( "`rbenv lock` Command\n" ).at_the_start_of out_io
          it_should_print_nothing_to err_io
        end      
      end
    end
    
    describe "plugin usage: `$ rbenv lock --usage`" do
      status, out_io, err_io = run_args.call [ "--usage" ]
      
      it_should_succeed status
      it_should_print( "Usage: rbenv lock add|" ).at_the_start_of out_io
      it_should_print_nothing_to err_io
    end
    
    describe "command help through `help` command" do
      %w(-h --help help).each do |help_cmd_name|
        Rbenv::Lock::Cmd.all.each do |cmd|
          cmd.names.each do |cmd_name|
            describe "$ `rbenv lock #{help_cmd_name} #{cmd_name}`" do
              status, out_io, err_io = run_args.call [ help_cmd_name, cmd_name ]
              
              it_should_succeed status
              it_should_print( "`rbenv lock #{cmd.canonical_name}` Command\n" )
                .at_the_start_of out_io
              it_should_print_nothing_to err_io
            end
          end
        end  
      end
    end
    
    describe "command usage through `help` command" do
      %w(-h --help help).each do |help_cmd_name|
        Rbenv::Lock::Cmd.all.each do |cmd|
          cmd.names.each do |cmd_name|
            describe "$ `rbenv lock #{help_cmd_name} --usage #{cmd_name}`" do
              status, out_io, err_io =
                run_args.call [ help_cmd_name, "--usage", cmd_name ]
              
              it_should_succeed status
              it_should_print( "Usage: rbenv lock #{cmd.canonical_name}" )
                .at_the_start_of out_io
              it_should_print_nothing_to err_io
            end
          end
        end  
      end
    end
    
  end
end
