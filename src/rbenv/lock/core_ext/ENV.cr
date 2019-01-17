module ENV
  def self.missing?( name : String ) : Bool
    value = self[ name ]?
    value.nil? || value == ""
  end
end