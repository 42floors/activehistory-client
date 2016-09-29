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
require 'activecortex'

ActiveCortex.configure({
  url: 'http://activecortex.com'
})
ActiveRecord::Base.establish_connection({
  adapter: 'postgresql',
  database: 'activecortex-client-test'
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
    WebMock.stub_request(:any, /^http:\/\/activecortex.com\/.*/)
  end
  
  def assert_posted(path, &block)
    assert_requested(:post, "#{ActiveCortex.url}#{path}", times: 1, &block)
  end
  
  def assert_not_posted(path)
    assert_not_requested(:post, "#{ActiveCortex.url}#{path}")
  end
  
  include ActiveRecord::TestFixtures
  include FactoryGirl::Syntax::Methods
end

# ActiveRecord::Base.logger = Logger.new(STDOUT)
