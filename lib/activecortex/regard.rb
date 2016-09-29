class ActiveCortex::Regard
  
  def initialize(id)
    @subject = id
  end
  
  def as_json
    { subject: @subject }
  end

end