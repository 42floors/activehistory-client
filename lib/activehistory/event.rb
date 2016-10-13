class ActiveHistory::Event
  
  attr_accessor :id, :ip, :user_agent, :session_id, :metadata, :timestamp, :performed_by_id, :performed_by_type, :actions
  
  def initialize(attrs={})
    attrs.each do |k,v|
      self.send("#{k}=", v)
    end

    @actions = []
    @timestamp ||= Time.now
  end
  
  def action!(action)
    action = ActiveHistory::Action.new(action)
    @actions << action
    action
  end
  
  def action_for(type, id)
    @actions.find { |a| a.subject_type.to_s == type.to_s && a.subject_id.to_s == id.to_s }
  end
  
  def save!
    return if @actions.empty?
    
    if id
      ActiveHistory.connection.post('/actions', {
        actions: actions.as_json.map{|json| json[:event_id] = id; json}
      })
    else
      response = ActiveHistory.connection.post('/events', self.as_json)
      self.id = JSON.parse(response.body)['id'] if response.body
    end
    
    self
  end
  
  def as_json
    {
      ip:                   ip,
      user_agent:           user_agent,
      session_id:           session_id,
      metadata:             metadata,
      performed_by_type:    performed_by_type,
      performed_by_id:      performed_by_id,
      timestamp:            timestamp.utc.iso8601(3),
      actions:              actions.as_json
    }
  end
  
end