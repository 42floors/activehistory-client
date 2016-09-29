class ActiveCortex::Regard
  
  def initialize(class_name, id)
    @subject_type = class_name
    @subject_id = id
  end
  
  def as_json
    { subject_id: @subject_id, subject_type: @subject_type }
  end

end