class Hash
  def merge_and_delete_nils!( other : Hash )
    other.each { |key, value|
      if value.nil?
        delete key
      else
        self[ key ] = value
      end
    }
    
    self
  end
end
