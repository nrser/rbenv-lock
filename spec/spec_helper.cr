require "spec"

ROOT = File.expand_path "..", __DIR__

def _path( *path : String ) : String
  File.join ROOT, *path
end

def _file( *path : String )
  File.open _path( *path ), "r" do |file|
    yield file
  end
end
