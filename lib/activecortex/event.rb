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
  
  def action_for(id)
    @actions.find { |a| a.subject == id }
  end
  
  def regard!(regard)
    @regards << regard
  end
  
  def save!
    return if @actions.empty?
    
    ActiveHistory.connection.post('/events', self.as_json)
  end
  
  def as_json
    {
      ip:         @attrs[:ip],
      user_agent: @attrs[:user_agent],
      session_id: @attrs[:session_id],
      account:    @attrs[:account],
      api_key:    @attrs[:api_key],
      metadata:   @attrs[:metadata],
      timestamp:  @attrs[:timestamp].utc.iso8601(3),
      actions:    @actions.map(&:as_json),
      regards:    @regards.map(&:as_json)
    }
  end
  
  def encapsulate
  ensure
  end

end