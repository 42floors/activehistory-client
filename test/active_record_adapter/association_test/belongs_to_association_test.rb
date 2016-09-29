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

    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size

      assert_equal 'update',   req_data['actions'][1]['type']
      assert_equal 'Account',  req_data['actions'][1]['subject_type']
      assert_equal @model.id,  req_data['actions'][1]['subject_id']
      assert_equal [[], [@target.id]], req_data['actions'][1]['diff']['photo_ids']
    end
  end
  
  test 'TargetModel.update removes from association' do
    @model = create(:account)
    @target = create(:photo, account: @model)
    WebMock::RequestRegistry.instance.reset!
    
    travel_to(@time) { @target.update(account: nil) }
    
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size

      assert_equal 'update',   req_data['actions'][1]['type']
      assert_equal 'Account',  req_data['actions'][1]['subject_type']
      assert_equal @model.id,  req_data['actions'][1]['subject_id']
      assert_equal [[@target.id], []], req_data['actions'][1]['diff']['photo_ids']
    end
  end
  
  test 'TargetModel.update changes association' do
    @model1 = create(:account)
    @model2 = create(:account)
    @target = create(:photo, account: @model1)
    WebMock::RequestRegistry.instance.reset!
    
    travel_to(@time) { @target.update(account: @model2) }
    
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 3, req_data['actions'].size

      assert_equal 'update',   req_data['actions'][1]['type']
      assert_equal 'Account',  req_data['actions'][1]['subject_type']
      assert_equal @model1.id,  req_data['actions'][1]['subject_id']
      assert_equal [[@target.id], []], req_data['actions'][1]['diff']['photo_ids']
      
      assert_equal 'update',   req_data['actions'][2]['type']
      assert_equal 'Account',  req_data['actions'][2]['subject_type']
      assert_equal @model2.id,  req_data['actions'][2]['subject_id']
      assert_equal [[], [@target.id]], req_data['actions'][2]['diff']['photo_ids']
    end
  end
  
  test 'TargetModel.destroy removes from association' do
    @model = create(:account)
    @target = create(:photo, account: @model)
    WebMock::RequestRegistry.instance.reset!
    
    travel_to(@time) { @target.destroy }
    
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size

      assert_equal 'update',   req_data['actions'][1]['type']
      assert_equal 'Account',  req_data['actions'][1]['subject_type']
      assert_equal @model.id,  req_data['actions'][1]['subject_id']
      assert_equal [[@target.id], []], req_data['actions'][1]['diff']['photo_ids']
    end
  end
  
end