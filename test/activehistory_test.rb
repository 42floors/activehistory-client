require 'test_helper'

class ActiveHistoryTest < ActiveSupport::TestCase

  def setup
    super
    @time = (Time.now.utc + 2).change(usec: 0)
  end

  test '::encapsulate(EVENT_ID) appends action to EVENT_ID'

  test '::encapsulate(event) appends actions to the given event' do
    @property = create(:property, name: 'unkown')
    WebMock::RequestRegistry.instance.reset!

    event = ActiveHistory::Event.create!

    ActiveHistory.encapsulate(event) do
      @property.name = 'Empire State Building'
      travel_to(@time) { @property.save }
    end

    assert_posted('/actions') do |req|
      assert_action_for @property, {
        timestamp: @time.iso8601(3),
        type: 'update',
        event_id: event.id,
        subject_type: 'Property',
        subject_id: @property.id,
        diff: { name: ['unkown', 'Empire State Building'] }
      }.as_json
    end

    WebMock::RequestRegistry.instance.reset!

    ActiveHistory.encapsulate(event) do
      @property.name = 'Empire State'
      travel_to(@time) { @property.save }
    end

    assert_posted('/actions') do |req|
      assert_action_for @property, {
        timestamp: @time.iso8601(3),
        type: 'update',
        event_id: event.id,
        subject_type: 'Property',
        subject_id: @property.id,
        diff: { name: ['Empire State Building', 'Empire State'] }
      }.as_json
    end

  end

  test '::encapsulate' do
    @property = create(:property, name: 'unkown')
    WebMock::RequestRegistry.instance.reset!

    ActiveHistory.encapsulate do
      @property.name = 'Empire State Building'
      travel_to(@time) { @property.save }

      eid = nil
      assert_posted("/events") do
        eid = @req['id']
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

      WebMock::RequestRegistry.instance.reset!
      @property.name = "Crysler Building"
      travel_to(@time + 1) { @property.save }
      
      assert_posted("/actions") do
        assert_action_for @property, {
          event_id: eid,
          timestamp: (@time + 1).iso8601(3),
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
  
end