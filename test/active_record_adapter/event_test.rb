require 'test_helper'

class EventTest < ActiveSupport::TestCase
  
  def setup
    super
    @time = Time.now.utc.change(usec: 0)
  end

  test 'Data captured from Event encalpsulation' do
    data = {
      ip: '127.0.0.1',
      user_agent:         'user-agent',
      session_id:         'session-id',
      performed_by_type:  'model',
      performed_by_id:    'id',
      api_key:            'api-key',
      metadata:           {random: 'stuff'},
      timestamp:          Time.now
    }
    
    # TODO: timestamp:  @attrs[:timestamp].iso8601(3),
    ActiveHistory.encapsulate(data) do
      create(:property)
      create(:property)
    end
    
    assert_requested(:post, "http://activehistory.com/events", times: 1) do |req|
      req_data = JSON.parse(req.body)
      data.each do |k, v|
        assert_equal v.is_a?(Time) ? v.utc.iso8601(3) : v.as_json, req_data[k.to_s]
      end
      
      assert_equal 2, req_data['actions'].size
    end
  end
  
  test 'Timestamp gets sent with Event' do
    travel_to @time do
      ActiveHistory.encapsulate { create(:property) }
    end
    
    assert_requested(:post, "http://activehistory.com/events", times: 1) do |req|
      assert_equal @time.iso8601(3), JSON.parse(req.body)['timestamp']
    end
  end
  
  test 'Event not captured it no actions taken' do
    ActiveHistory.encapsulate { 1 + 1 }
    
    assert_not_requested :any, /^http:\/\/activehistory.com\/.*/
  end
  
  test 'Nothing sent on a model not being tracked' do
    ActiveHistory.encapsulate { create(:unobserved_model) }

    assert_not_requested :any, /^http:\/\/activehistory.com\/.*/
  end
  
end