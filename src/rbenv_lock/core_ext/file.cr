class File
  def self.join?( *parts ) : String?
    join? parts
  end
  
  def self.join?( parts : Array | Tuple ) : String?
    if parts.any? { |part| part.nil? }
      nil
    else
      join parts.map { |part| part.to_s }
    end
  end
end