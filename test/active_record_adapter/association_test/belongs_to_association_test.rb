require 'test_helper'

class BelongsToAssociationTest < ActiveSupport::TestCase
  
  def setup
    super
    @time = (Time.now.utc + 2).change(usec: 0)
  end
  
  test 'TargetModel.create' do
    @model = create(:account)
    WebMock::RequestRegistry.instance.reset!
    
    @target = travel_to(@time) { create(:photo, account: @model) }

    assert_posted("/events") do
      assert_action_for @model, {
        diff: { photo_ids: [[], [@target.id]] },
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Account",
        subject_id: @model.id,
      }
    end
  end

  test 'TargetModel.update removes from association' do
    @model = create(:account)
    @target = create(:photo, account: @model)
    WebMock::RequestRegistry.instance.reset!

    travel_to(@time) { @target.update(account: nil) }

    assert_posted("/events") do
      assert_action_for @model, {
        diff: { photo_ids: [[@target.id], []] },
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Account",
        subject_id: @model.id,
      }
    end
  end

  test 'TargetModel.update changes association' do
    @model1 = create(:account)
    @model2 = create(:account)
    @target = create(:photo, account: @model1)
    WebMock::RequestRegistry.instance.reset!

    travel_to(@time) { @target.update(account: @model2) }

    assert_posted("/events") do
      assert_action_for @model1, {
        diff: { photo_ids: [[@target.id], []] },
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Account",
        subject_id: @model1.id,
      }
      
      assert_action_for @model2, {
        diff: { photo_ids: [[], [@target.id]] },
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Account",
        subject_id: @model2.id,
      }
    end
  end

  test 'TargetModel.destroy removes from association' do
    @model = create(:account)
    @target = create(:photo, account: @model)
    WebMock::RequestRegistry.instance.reset!

    travel_to(@time) { @target.destroy }

    assert_posted("/events") do
      assert_action_for @model, {
        diff: { photo_ids: [[@target.id], []] },
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Account",
        subject_id: @model.id,
      }
    end
  end

end