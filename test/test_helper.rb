# Test within this source tree versus an installed gem
$LOAD_PATH << File.expand_path('../lib', __FILE__)

require 'active_support'
require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/reporters'
require 'webmock/minitest'
require 'factory_bot'
require 'faker'
require 'byebug'


WebMock.disable_net_connect!
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require 'active_record'
require 'activehistory'

ActiveHistory.configure({
  url: 'http://activehistory.com',
  logger: Logger.new("/dev/null")
})
ActiveRecord::Base.establish_connection({
  adapter: 'postgresql',
  database: 'activehistory-client-test'
})
ActiveRecord::Migration.suppress_messages do
  require File.expand_path('../schema', __FILE__)
  ActiveRecord::Migration.execute("SELECT c.relname FROM pg_class c WHERE c.relkind = 'S'").each_row do |row|
    ActiveRecord::Migration.execute("ALTER SEQUENCE #{row[0]} RESTART WITH #{rand(50_000)}")
  end
end

require File.expand_path('../models', __FILE__)

FactoryBot.find_definitions

class ActiveSupport::TestCase
  
  # File 'lib/active_support/testing/declarative.rb'
  def self.test(name, &block)
    test_name = "test_#{name.gsub(/\s+/, '_')}".to_sym
    defined = method_defined? test_name
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        skip "No implementation provided for #{name}"
      end
    end
  end

  def setup
    WebMock.stub_request(:any, /^http:\/\/activehistory.com\/.*/)
  end
  
  set_callback(:teardown, :after) do
    if !Thread.current[:activehistory_event].nil?
      raise 'no nil'
    end
  end
  
  def assert_posted(path, &block)
    assert_requested(:post, "#{ActiveHistory.url}#{path}", times: 1) do |req|
      @req = JSON.parse(req.body)
      block.call @req
    end
  end
  
  def assert_action_for(model, expected)
    action = @req['actions'].find do |a|
      a['subject_type'] == model.class.base_class.model_name.name && a['subject_id'] == model.id
    end

    assert_equal(expected.as_json, action)
  end
  
  def assert_no_action_for(model)
    action = @req['actions'].find do |a|
      a['subject_type'] == model.class.base_class.model_name.name && a['subject_id'] == model.id
    end

    assert_nil action
  end
  
  def assert_not_posted(path)
    assert_not_requested(:post, "#{ActiveHistory.url}#{path}")
  end
  
  include ActiveRecord::TestFixtures
  include FactoryBot::Syntax::Methods
end

# ActiveRecord::Base.logger = Logger.new(STDOUT)
