class ActiveHistory::Event
  
  attr_accessor :actions, :regards, :timestamp
  
  def initialize(attrs={})
    @attrs = attrs
    @attrs[:timestamp] ||= Time.now
    @actions = []
    @regards = []
  end
  
  def action!(action)
    action = ActiveHistory::Action.new(action)
    @actions << action
    action
  end
  
  def action_for(type, id)
    @actions.find { |a| a.subject_type.to_s == type.to_s && a.subject_id.to_s == id.to_s }
  end
  
  def regard!(regard)
    @regards << regard
  end
  
  def save!
    return if @actions.empty?
    
    ActiveHistory.connection.post('/events', {event: self.as_json})
  end
  
  def as_json
    {
      ip:                   @attrs[:ip],
      user_agent:           @attrs[:user_agent],
      session_id:           @attrs[:session_id],
      performed_by_type:    @attrs[:performed_by_type],
      performed_by_id:      @attrs[:performed_by_id],
      api_key:              @attrs[:api_key],
      metadata:             @attrs[:metadata],
      timestamp:            @attrs[:timestamp].utc.iso8601(3),
      actions:              @actions.map(&:as_json),
      regards:              @regards.map(&:as_json)
    }
  end
  
  def encapsulate
  ensure
  end

end