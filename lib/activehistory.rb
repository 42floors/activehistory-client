require 'logger'

module ActiveHistory

  mattr_accessor :connection, :logger, :adapter

  UUIDV4 = /^[0-9A-F]{8}-[0-9A-F]{4}-[4][0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i

  def self.configure(settings)
    self.adapter = settings.delete(:adapter) || :request
    self.logger = settings&.delete(:logger) || Logger.new(STDOUT)
    @@connection = ActiveHistory::Connection.new(settings)

    if self.adapter == :request && defined?(ActiveRecord::VERSION)
      require 'activehistory/adapters/active_record'
      ActiveRecord::Base.include(ActiveHistory::Adapter::ActiveRecord)
    elsif self.adapter == :wal
      ActiveRecord::Base.include(ActiveHistory::Adapter::Wal)
    end
  end

  def self.configured?
    class_variable_defined?(:@@connection) && !@@connection.nil?
  end

  def self.url
    @@connection.url
  end

  def self.encapsulate(attributes_or_event={}, &block)
    if adapter == :wal
      encapsulate_via_wal(attributes_or_event, &block)
    else
      encapsulate_via_request(attributes_or_event,&block)
    end
  end

  def self.current_event(timestamp: nil)
    Thread.current[:activehistory_event]
  end

  private

  def self.encapsulate_via_wal(attributes_or_event={}, &block)
    if attributes_or_event.is_a?(ActiveHistory::Event)
      event = attributes_or_event
    else
      event = ActiveHistory::Event.new(attributes_or_event)
    end

    Thread.current[:activehistory_event] = event

    yield
  ensure
    Thread.current[:activehistory_event] = nil
  end

  def self.encapsulate_via_request(attributes_or_event={}, &block)
    if attributes_or_event.is_a?(ActiveHistory::Event)
      event = attributes_or_event
    else
      event = ActiveHistory::Event.new(attributes_or_event)
    end

    Thread.current[:activehistory_event] = event

    yield
  ensure
    if configured? && Thread.current[:activehistory_event] && !Thread.current[:activehistory_event].actions.empty?
      Thread.current[:activehistory_event].save!
    end
    Thread.current[:activehistory_event] = nil
  end

end

require 'activehistory/connection'
require 'activehistory/event'
require 'activehistory/action'
require 'activehistory/regard'
require 'activehistory/version'
require 'activehistory/exceptions'

