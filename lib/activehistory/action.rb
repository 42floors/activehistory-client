class ActiveHistory::Action

  attr_accessor :id, :event_id, :type, :timestamp, :subject_type, :subject_id, :diff

  def initialize(attrs)
    attrs.each do |k,v|
      self.send("#{k}=", v)
    end
    self.diff ||= {}
  end
  
  def as_json
    {
      diff:         diff.as_json,
      subject_type: subject_type,
      subject_id:   subject_id,
      timestamp:    timestamp.iso8601(3),
      type:         type,
      event_id:     event_id,
      id:           id
    }
  end

end
