require 'test_helper'

class DestroyTest < ActiveSupport::TestCase
  
  def setup
    super
    @time = (Time.now.utc + 2).change(usec: 0)
  end
  
  test '::destroy creates an Action' do
    @property = create(:property)
    WebMock::RequestRegistry.instance.reset!
    
    travel_to(@time) { @property.destroy }
    
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 1, req_data['actions'].size
      
      assert_equal req_data['actions'][0], {
        timestamp: @time.iso8601(3),
        type: 'destroy',
        subject_id: @property.id,
        subject_type: 'Property',
        diff: {
          id: [@property.id, nil],
          name: [@property.name, nil],
          aliases: [[], nil],
          description: [@property.description, nil],
          constructed: [@property.constructed, nil],
          size: [@property.size, nil],
          created_at: [@property.created_at, nil],
          active: [@property.active, nil]
        }
      }.as_json
    end
  end
  
end