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
  
  test 'has_many=' do
    @property = create(:property)
    @photo1 = create(:photo)
    @photo2 = create(:photo)
    WebMock::RequestRegistry.instance.reset!
    
    travel_to(@time) { @property.photos = [@photo1] }
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size
      
      assert_equal req_data['actions'][0], {
        diff: { property_id: [nil, @property.id] },
        subject_type: "Photo",
        subject_id: @photo1.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json

      assert_equal req_data['actions'][1], {
        diff: { photo_ids: [[], [@photo1.id]] },
        subject_type: "Property",
        subject_id: @property.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json
    end
    
    WebMock::RequestRegistry.instance.reset!
    travel_to(@time) { @property.photos = [@photo2] }
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal req_data['actions'].size, 3
      
      assert_equal req_data['actions'][0], {
        diff: { property_id: [nil, @property.id] },
        subject_type: "Photo",
        subject_id: @photo2.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json
      
      assert_equal req_data['actions'][1], {
        diff: { photo_ids: [[@photo1.id], [@photo2.id]] },
        subject_type: "Property",
        subject_id: @property.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json
      
      assert_equal req_data['actions'][2], {
        diff: { property_id: [@property.id, nil] },
        subject_type: "Photo",
        subject_id: @photo1.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json
    end
  end
  
  test 'has_many_ids=' do
    @property = create(:property)
    @photo1 = create(:photo)
    @photo2 = create(:photo)
    WebMock::RequestRegistry.instance.reset!
    
    travel_to(@time) { @property.photo_ids = [@photo1].map(&:id) }
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size
      
      assert_equal req_data['actions'][1], {
        diff: { photo_ids: [[], [@photo1.id]] },
        subject_type: "Property",
        subject_id: @property.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json
      
      assert_equal req_data['actions'][0], {
        diff: { property_id: [nil, @property.id] },
        subject_type: "Photo",
        subject_id: @photo1.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json
    end
    
    WebMock::RequestRegistry.instance.reset!
    travel_to(@time) { @property.photo_ids = [@photo2].map(&:id) }
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal req_data['actions'].size, 3
      
      assert_equal req_data['actions'][0], {
        diff: { property_id: [nil, @property.id] },
        subject_type: "Photo",
        subject_id: @photo2.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json
      
      assert_equal req_data['actions'][1], {
        diff: { photo_ids: [[@photo1.id], [@photo2.id]] },
        subject_type: "Property",
        subject_id: @property.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json
      
      assert_equal req_data['actions'][2], {
        diff: { property_id: [@property.id, nil] },
        subject_type: "Photo",
        subject_id: @photo1.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json
    end
  end
  
  test 'has_many.clear' do
    @photo1 = create(:photo)
    @photo2 = create(:photo)
    @property = create(:property, photos: [@photo1, @photo2])
    WebMock::RequestRegistry.instance.reset!
    
    travel_to(@time) { @property.photos.clear }
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 3, req_data['actions'].size
      
      assert_equal req_data['actions'][0], {
        diff: { photo_ids: [[@photo1, @photo2].map(&:id), []] },
        subject_type: "Property",
        subject_id: @property.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json
      
      assert_equal req_data['actions'][1], {
        diff: { property_id: [@property.id, nil] },
        subject_type: "Photo",
        subject_id: @photo1.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json
      
      assert_equal req_data['actions'][2], {
        diff: { property_id: [@property.id, nil] },
        subject_type: "Photo",
        subject_id: @photo2.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json
    end
  end
  
  test 'has_many.create'
   
end