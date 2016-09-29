class ActiveCortex::Action

  attr_accessor :type, :timestamp, :subject_type, :subject_id, :diff

  def initialize(attrs)
    attrs.each do |k,v|
      self.send("#{k}=", v)
    end
  end
  
  def as_json
    {
      diff: diff.as_json,
      subject_id:   @subject_id,
      subject_type: @subject_type,
      timestamp:    @timestamp.iso8601(3),
      type:         @type
    }
  end

end
