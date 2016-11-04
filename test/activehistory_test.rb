require 'test_helper'

class ActiveHistoryTest < ActiveSupport::TestCase

  def setup
    super
    @time = (Time.now.utc + 2).change(usec: 0)
  end

  test '::encapsulate(EVENT_ID) appends action to EVENT_ID'
  
  test '::encapsulate' do
    @property = create(:property, name: 'unkown')
    WebMock::RequestRegistry.instance.reset!

    ActiveHistory.encapsulate do
      @property.name = 'Empire State Building'
      travel_to(@time) { @property.save }

      @property.name = "Crysler Building"
      travel_to(@time + 1) { @property.save }
    end

    assert_posted("/events") do
      assert_action_for @property, {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Property",
        subject_id: @property.id,
        diff: {
          name: ['unkown', 'Empire State Building']
        }
      }.as_json
    end

    assert_posted("/events") do
      assert_action_for @property, {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Property",
        subject_id: @property.id,
        diff: {
          name: ['Empire State Building', 'Crysler Building']
        }
      }.as_json
    end
    
  end
  
end