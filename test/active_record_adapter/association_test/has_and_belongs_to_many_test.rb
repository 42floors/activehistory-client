require 'test_helper'

class HasAndBelongsToManyAssociationTest < ActiveSupport::TestCase
  
  def setup
    super
    @time = (Time.now.utc + 2).change(usec: 0)
  end

  test '::create with existing has_and_belongs_to_many association' do
    @property = create(:property)
    WebMock::RequestRegistry.instance.reset!

    @region = travel_to(@time) { create(:region, properties: [@property]) }
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size

      assert_equal req_data['actions'][0], {
        diff: {
          id: [nil, @region.id],
          name: [nil, @region.name],
          property_ids: [[], [@property.id]]
        },
        subject_type: "Region",
        subject_id: @region.id,
        timestamp: @time.iso8601(3),
        type: 'create'
      }.as_json

      assert_equal req_data['actions'][1], {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Property",
        subject_id: @property.id,
        diff: {
          region_ids: [[], [@region.id]]
        }
      }.as_json
    end
  end

  test '::create with new has_and_belongs_to_many association' do
    WebMock::RequestRegistry.instance.reset!

    @region = travel_to(@time) { create(:region, properties: [build(:property)]) }
    @property = @region.properties.first

    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size

      assert_equal req_data['actions'][0], {
        diff: {
          id: [nil, @region.id],
          name: [nil, @region.name],
          property_ids: [[], [@property.id]]
        },
        subject_type: "Region",
        subject_id: @region.id,
        timestamp: @time.iso8601(3),
        type: 'create'
      }.as_json

      assert_equal req_data['actions'][1], {
        timestamp: @time.iso8601(3),
        type: 'create',
        subject_type: "Property",
        subject_id: @property.id,
        diff: {
          id: [nil, @property.id],
          name: [nil, @property.name],
          description: [nil, @property.description],
          constructed: [nil, @property.constructed],
          size: [nil, @property.size],
          created_at: [nil, @property.created_at],
          aliases: [nil, []],
          active: [nil, @property.active],
          region_ids: [[], [@region.id]]
        }
      }.as_json
    end
  end

  test '::update with adding existing has_and_belongs_to_many association' do
    @property = create(:property)
    @region = create(:region)
    WebMock::RequestRegistry.instance.reset!

    travel_to(@time) { @region.update(properties: [@property]) }

    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size

      assert_equal req_data['actions'][0], {
        diff: {
          property_ids: [[], [@property.id]]
        },
        subject_type: "Region",
        subject_id: @region.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json

      assert_equal req_data['actions'][1], {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Property",
        subject_id: @property.id,
        diff: {
          region_ids: [[], [@region.id]]
        }
      }.as_json
    end
  end

  test '::update with adding new has_and_belongs_to_many association' do
    @region = create(:region)
    WebMock::RequestRegistry.instance.reset!

    travel_to(@time) { @region.update(properties: [build(:property)]) }
    @property = @region.properties.first
    
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size

      assert_equal req_data['actions'][0], {
        timestamp: @time.iso8601(3),
        type: 'create',
        subject_type: "Property",
        subject_id: @property.id,
        diff: {
          id: [nil, @property.id],
          name: [nil, @property.name],
          description: [nil, @property.description],
          constructed: [nil, @property.constructed],
          size: [nil, @property.size],
          created_at: [nil, @property.created_at],
          aliases: [nil, []],
          active: [nil, @property.active],
          region_ids: [[], [@region.id]]
        }
      }.as_json

      assert_equal req_data['actions'][1], {
        diff: {
          property_ids: [[], [@property.id]]
        },
        subject_type: "Region",
        subject_id: @region.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json
    end
  end

  test '::update with removing has_and_belongs_to_many association' do
    @property = create(:property)
    @region = create(:region, properties: [@property])
    WebMock::RequestRegistry.instance.reset!

    travel_to(@time) { @region.update(properties: []) }

    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size

      assert_equal req_data['actions'][0], {
        diff: {
          property_ids: [[@property.id], []]
        },
        subject_type: "Region",
        subject_id: @region.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json

      assert_equal req_data['actions'][1], {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Property",
        subject_id: @property.id,
        diff: {
          region_ids: [[@region.id], []]
        }
      }.as_json
    end
  end
  
  test '::destroying updates has_and_belongs_to_many associations' do
    @property = create(:property)
    @region = create(:region, properties: [@property])
    WebMock::RequestRegistry.instance.reset!
    
    travel_to(@time) { @region.destroy }

    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size

      assert_equal req_data['actions'][0], {
        diff: {
          id: [@region.id, nil],
          name: [@region.name, nil],
          property_ids: [[@property.id], []]
        },
        subject_type: "Region",
        subject_id: @region.id,
        timestamp: @time.iso8601(3),
        type: 'destroy'
      }.as_json

      assert_equal req_data['actions'][1], {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Property",
        subject_id: @property.id,
        diff: {
          region_ids: [[@region.id], []]
        }
      }.as_json
    end
  end


  test 'has_and_belongs_to_many <<'
  test 'has_and_belongs_to_many.delete'
  test 'has_and_belongs_to_many.destroy'
  test 'has_and_belongs_to_many='
  test 'has_and_belongs_to_many_ids='
  test 'has_and_belongs_to_many.clear'
  test 'has_and_belongs_to_many.create'
  
end