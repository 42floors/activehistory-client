require 'globalid'
require 'securerandom'

GlobalID::Locator.use :activehistory do |gid|
  ActiveHistory::Event.new({ id: gid.model_id })
end

class ActiveHistory::Event
  include GlobalID::Identification

  attr_accessor :id, :metadata, :timestamp, :actions
  
  def initialize(attrs={})
    attrs.each do |k,v|
      self.send("#{k}=", v)
    end

    if id
      @persisted = true
    else
      @persisted = false
      @id ||= SecureRandom.uuid
    end

    @actions ||= []
    @timestamp ||= Time.now
    @metadata ||= {}
  end

  def persisted?
    @persisted
  end

  def action!(action)
    action = ActiveHistory::Action.new(action)
    @actions << action
    action
  end
  
  def action_for(type, id, new_options=nil)
    type = type.base_class.model_name.name if !type.is_a?(String)
    action = @actions.find { |a| a.subject_type.to_s == type.to_s && a.subject_id.to_s == id.to_s }
    
    if new_options
      if action
        action.diff.merge!(new_options[:diff]) if new_options.has_key?(:diff)
        action
      else
        action!({ subject_type: type, subject_id: id, type: :update }.merge(new_options))
      end

    else
      action
    end
  end

  def self.create!(attrs={})
    event = self.new(attrs)
    event.save!
    event
  end
    
  def save!
    persisted? ? _update : _create
  end
  
  def _update
    return if actions.empty?
    actions.delete_if { |a| a.diff.empty? }
    payload = JSON.generate({actions: actions.as_json.map{ |json| json[:event_id] = id; json }})
    ActiveHistory.logger.debug("[ActiveHistory] POST /actions WITH #{payload}")
    ActiveHistory.connection.post('/actions', payload)
    @actions = []
  end
  
  def _create
    actions.delete_if { |a| a.diff.empty? }
    payload = JSON.generate(self.as_json)
    ActiveHistory.logger.debug("[ActiveHistory] POST /events WITH #{payload}")
    ActiveHistory.connection.post('/events', payload)
    @actions = []
    @persisted = true
  end

  def as_json
    {
      id:                   id,
      metadata:             metadata,
      timestamp:            timestamp.utc.iso8601(3),
      actions:              actions.as_json
    }
  end

  def to_gid_param(options={})
    to_global_id(options).to_param
  end

  def to_global_id(options={})
    @global_id ||= GlobalID.create(self, { app: :activehistory }.merge(options))
  end
  
  def to_sgid_param(options={})
    to_signed_global_id(options).to_param
  end
  
  def to_signed_global_id(options={})
     SignedGlobalID.create(self, { app: :activehistory }.merge(options))
  end

end