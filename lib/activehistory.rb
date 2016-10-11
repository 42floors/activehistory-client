module ActiveHistory
  
  mattr_accessor :connection
  
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
    Thread.current[:activehistory_event] = id_or_options
    yield
    event = if Thread.current[:activehistory_event].is_a?(ActiveHistory::Event)
      Thread.current[:activehistory_event].save!
    end
    event
  ensure
    Thread.current[:activehistory_event] = nil
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
