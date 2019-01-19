module ENV
  def self.missing?( name : String ) : Bool
    value = self[ name ]?
    value.nil? || value == ""
  end
  
  def self.present?( name : String ) : Bool
    !missing?( name )
  end
end