# Test within this source tree versus an installed gem
$LOAD_PATH << File.expand_path('../lib', __FILE__)

require 'active_support'
require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/reporters'
require 'webmock/minitest'
require 'factory_girl'
require 'faker'


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

FactoryGirl.find_definitions

class ActiveSupport::TestCase
  
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
  include FactoryGirl::Syntax::Methods
end

# ActiveRecord::Base.logger = Logger.new(STDOUT)
