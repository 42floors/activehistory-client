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
    
    assert_posted("/events") do
      assert_action_for @photo, {
        diff: {
          id: [nil, @photo.id],
          property_id: [nil, @property.id],
          format: [nil, @photo.format]
        },
        subject_type: "Photo",
        subject_id: @photo.id,
        timestamp: @time.iso8601(3),
        type: 'create'
      }

      assert_action_for @property, {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Property",
        subject_id: @property.id,
        diff: {
          photo_ids: [[], [@photo.id]]
        }
      }
    end
  end

  test '::update with has_many association' do
    @property = create(:property)
    @photo = create(:photo, property: @property)
    WebMock::RequestRegistry.instance.reset!

    travel_to(@time) { @photo.update(property: nil) }

    assert_posted("/events") do
      assert_action_for @photo, {
        diff: {
          property_id: [@property.id, nil]
        },
        subject_type: "Photo",
        subject_id: @photo.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }

      assert_action_for @property, {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Property",
        subject_id: @property.id,
        diff: {
          photo_ids: [[@photo.id], []]
        }
      }
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
    assert_posted("/events") do
      assert_action_for @photo1, {
        diff: { property_id: [nil, @property.id] },
        subject_type: "Photo",
        subject_id: @photo1.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }

      assert_action_for @property, {
        diff: { photo_ids: [[], [@photo1.id]] },
        subject_type: "Property",
        subject_id: @property.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }
    end
    
    WebMock::RequestRegistry.instance.reset!
    travel_to(@time) { @property.photos = [@photo2] }
    assert_posted("/events") do      
      assert_action_for @photo2, {
        diff: { property_id: [nil, @property.id] },
        subject_type: "Photo",
        subject_id: @photo2.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }
      
      assert_action_for @property, {
        diff: { photo_ids: [[@photo1.id], [@photo2.id]] },
        subject_type: "Property",
        subject_id: @property.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }
      
      assert_action_for @photo1, {
        diff: { property_id: [@property.id, nil] },
        subject_type: "Photo",
        subject_id: @photo1.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }
    end
  end
  
  test 'has_many_ids=' do
    @property = create(:property)
    @photo1 = create(:photo)
    @photo2 = create(:photo)
    WebMock::RequestRegistry.instance.reset!
    
    travel_to(@time) { @property.photo_ids = [@photo1].map(&:id) }
    assert_posted("/events") do
      assert_action_for @property, {
        diff: { photo_ids: [[], [@photo1.id]] },
        subject_type: "Property",
        subject_id: @property.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }
      
      assert_action_for @photo1, {
        diff: { property_id: [nil, @property.id] },
        subject_type: "Photo",
        subject_id: @photo1.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }
    end
    
    WebMock::RequestRegistry.instance.reset!
    travel_to(@time) { @property.photo_ids = [@photo2].map(&:id) }
    assert_posted("/events") do      
      assert_action_for @photo2, {
        diff: { property_id: [nil, @property.id] },
        subject_type: "Photo",
        subject_id: @photo2.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }
      
      assert_action_for @property, {
        diff: { photo_ids: [[@photo1.id], [@photo2.id]] },
        subject_type: "Property",
        subject_id: @property.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }
      
      assert_action_for @photo1, {
        diff: { property_id: [@property.id, nil] },
        subject_type: "Photo",
        subject_id: @photo1.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }
    end
  end
  
  test 'has_many.clear' do
    @photo1 = create(:photo)
    @photo2 = create(:photo)
    @property = create(:property, photos: [@photo1, @photo2])
    WebMock::RequestRegistry.instance.reset!
    
    travel_to(@time) { @property.photos.clear }
    assert_posted("/events") do |req|
      
      assert_action_for @property, {
        diff: { photo_ids: [[@photo1, @photo2].map(&:id), []] },
        subject_type: "Property",
        subject_id: @property.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }
      
      assert_action_for @photo1, {
        diff: { property_id: [@property.id, nil] },
        subject_type: "Photo",
        subject_id: @photo1.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }
      
      assert_action_for @photo2, {
        diff: { property_id: [@property.id, nil] },
        subject_type: "Photo",
        subject_id: @photo2.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }
    end
  end
  
  test 'has_many.create'
   
end