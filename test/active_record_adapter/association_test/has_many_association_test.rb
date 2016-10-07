require 'test_helper'

class HasManyAssociationTest < ActiveSupport::TestCase
  
  def setup
    super
    @time = (Time.now.utc + 2).change(usec: 0)
  end

  test '::create with has_many association' do
    @property = create(:property)
    WebMock::RequestRegistry.instance.reset!
    
    @photo = travel_to(@time) { create(:photo, property: @property) }
    
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size
      
      assert_equal req_data['actions'][0], {
        diff: {
          id: [nil, @photo.id],
          property_id: [nil, @property.id],
          format: [nil, @photo.format]
        },
        subject_type: "Photo",
        subject_id: @photo.id,
        timestamp: @time.iso8601(3),
        type: 'create'
      }.as_json

      assert_equal req_data['actions'][1], {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Property",
        subject_id: @property.id,
        diff: {
          photo_ids: [[], [@photo.id]]
        }
      }.as_json
    end
  end
  
  test '::update with has_many association' do
    @property = create(:property)
    @photo = create(:photo, property: @property)
    WebMock::RequestRegistry.instance.reset!
    
    travel_to(@time) { @photo.update(property: nil) }
    
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size
      
      assert_equal req_data['actions'][0], {
        diff: {
          property_id: [@property.id, nil]
        },
        subject_type: "Photo",
        subject_id: @photo.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json

      assert_equal req_data['actions'][1], {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Property",
        subject_id: @property.id,
        diff: {
          photo_ids: [[@photo.id], []]
        }
      }.as_json
    end
  end

  test 'has_many <<'
  test 'has_many.delete'
  test 'has_many.destroy'
  test 'has_many='
  test 'has_many_ids='
  test 'has_many.clear'
  test 'has_many.create'
   
end