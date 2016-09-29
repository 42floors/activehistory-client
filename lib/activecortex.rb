module ActiveCortex
  
  mattr_accessor :connection
  
  def self.configure(settings)
    @@connection = ActiveCortex::Connection.new(settings)
  end
  
  def self.url
    @@connection.url
  end

  def self.encapsulate(id_or_options=nil)
    Thread.current[:activecortex_event] = id_or_options
    yield
  ensure
    if Thread.current[:activecortex_event].is_a?(ActiveCortex::Event)
      Thread.current[:activecortex_event].save!
    end
    Thread.current[:activecortex_event] = nil
  end
  
end

require 'activecortex/connection'
require 'activecortex/event'
require 'activecortex/action'
require 'activecortex/regard'
require 'activecortex/version'
require 'activecortex/exceptions'

if defined?(ActiveRecord::VERSION)
  require 'activecortex/adapters/active_record'
  ActiveRecord::Base.include(ActiveCortex::Adapter::ActiveRecord)
end
