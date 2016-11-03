module ActiveHistory
  
  mattr_accessor :connection
  
  UUIDV4 = /^[0-9A-F]{8}-[0-9A-F]{4}-[4][0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i
  
  def self.configure(settings)
    @@connection = ActiveHistory::Connection.new(settings)
  end
  
  def self.configured?
    class_variable_defined?(:@@connection) && !@@connection.nil?
  end
  
  def self.url
    @@connection.url
  end

  def self.encapsulate(id_or_options={})
    Thread.current[:activehistory_save_lock] = true
    Thread.current[:activehistory_event] = id_or_options
    
    yield
    
    if configured? && Thread.current[:activehistory_event].is_a?(ActiveHistory::Event)
      Thread.current[:activehistory_event].save!
    end
  ensure
    Thread.current[:activehistory_save_lock] = false
    Thread.current[:activehistory_event] = nil
  end
  
  def self.current_event(timestamp: nil)
    timestamp ||= Time.now
    
    case Thread.current[:activehistory_event]
    when ActiveHistory::Event
      Thread.current[:activehistory_event]
    when Hash
      Thread.current[:activehistory_event][:timestamp] ||= timestamp
      Thread.current[:activehistory_event] = ActiveHistory::Event.new(Thread.current[:activehistory_event])
    when String
      Thread.current[:activehistory_event] = if Thread.current[:activehistory_event] =~ UUIDV4
        ActiveHistory::Event.new(id: Thread.current[:activehistory_event])
      else
        ActiveHistory::Event.new(timestamp: timestamp)
      end
    else
      Thread.current[:activehistory_event] = ActiveHistory::Event.new(timestamp: timestamp)
    end
  end
  
end

require 'activehistory/connection'
require 'activehistory/event'
require 'activehistory/action'
require 'activehistory/regard'
require 'activehistory/version'
require 'activehistory/exceptions'

if defined?(ActiveRecord::VERSION)
  require 'activehistory/adapters/active_record'
  ActiveRecord::Base.include(ActiveHistory::Adapter::ActiveRecord)
end
