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

  def self.encapsulate(attributes={}, &block)
    Thread.current[:activehistory_event] = ActiveHistory::Event.new(attributes)
    
    yield
  ensure
    Thread.current[:activehistory_event].save! if !Thread.current[:activehistory_event].actions.empty?
    Thread.current[:activehistory_event] = nil
  end
  
  def self.current_event(timestamp: nil)
    Thread.current[:activehistory_event]
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
