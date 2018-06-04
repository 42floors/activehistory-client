require 'test_helper'

class HasAndBelongsToManyAssociationTest < ActiveSupport::TestCase
  
  def setup
    super
    @time = (Time.now.utc + 2).change(usec: 0)
  end

  # test '::create with existing has_and_belongs_to_many association' do
  #   @property = create(:property)
  #   WebMock::RequestRegistry.instance.reset!

  #   @region = travel_to(@time) { create(:region, properties: [@property]) }
    
  #   assert_posted("/events") do
  #     assert_action_for @region, {
  #       diff: {
  #         id: [nil, @region.id],
  #         name: [nil, @region.name],
  #         property_ids: [[], [@property.id]]
  #       },
  #       subject_type: "Region",
  #       subject_id: @region.id,
  #       timestamp: @time.iso8601(3),
  #       type: 'create'
  #     }
      
  #     assert_action_for @property, {
  #       timestamp: @time.iso8601(3),
  #       type: 'update',
  #       subject_type: "Property",
  #       subject_id: @property.id,
  #       diff: {
  #         region_ids: [[], [@region.id]]
  #       }
  #     }
  #   end
  # end

  # test '::create with new has_and_belongs_to_many association' do
  #   @region = travel_to(@time) { create(:region, properties: [build(:property)]) }
  #   @property = @region.properties.first

  #   assert_posted("/events") do
  #     assert_action_for @region, {
  #       diff: {
  #         id: [nil, @region.id],
  #         name: [nil, @region.name],
  #         property_ids: [[], [@property.id]]
  #       },
  #       subject_type: "Region",
  #       subject_id: @region.id,
  #       timestamp: @time.iso8601(3),
  #       type: 'create'
  #     }

  #     assert_action_for @property, {
  #       timestamp: @time.iso8601(3),
  #       type: 'create',
  #       subject_type: "Property",
  #       subject_id: @property.id,
  #       diff: {
  #         id: [nil, @property.id],
  #         name: [nil, @property.name],
  #         description: [nil, @property.description],
  #         constructed: [nil, @property.constructed],
  #         size: [nil, @property.size],
  #         created_at: [nil, @property.created_at],
  #         aliases: [nil, []],
  #         active: [nil, @property.active],
  #         region_ids: [[], [@region.id]]
  #       }
  #     }
  #   end
  # end

  # test '::update with adding existing has_and_belongs_to_many association' do
  #   @property = create(:property)
  #   @region = create(:region)
  #   WebMock::RequestRegistry.instance.reset!

  #   travel_to(@time) { @region.update(properties: [@property]) }

  #   assert_posted("/events") do
  #     assert_action_for @region, {
  #       diff: {
  #         property_ids: [[], [@property.id]]
  #       },
  #       subject_type: "Region",
  #       subject_id: @region.id,
  #       timestamp: @time.iso8601(3),
  #       type: 'update'
  #     }

  #     assert_action_for @property, {
  #       timestamp: @time.iso8601(3),
  #       type: 'update',
  #       subject_type: "Property",
  #       subject_id: @property.id,
  #       diff: {
  #         region_ids: [[], [@region.id]]
  #       }
  #     }
  #   end
  # end

  # test '::update with adding new has_and_belongs_to_many association' do
  #   @region = create(:region)
  #   WebMock::RequestRegistry.instance.reset!

  #   travel_to(@time) { @region.update(properties: [build(:property)]) }
  #   @property = @region.properties.first
    
  #   assert_posted("/events") do
  #     assert_action_for @property, {
  #       timestamp: @time.iso8601(3),
  #       type: 'create',
  #       subject_type: "Property",
  #       subject_id: @property.id,
  #       diff: {
  #         id: [nil, @property.id],
  #         name: [nil, @property.name],
  #         description: [nil, @property.description],
  #         constructed: [nil, @property.constructed],
  #         size: [nil, @property.size],
  #         created_at: [nil, @property.created_at],
  #         aliases: [nil, []],
  #         active: [nil, @property.active],
  #         region_ids: [[], [@region.id]]
  #       }
  #     }

  #     assert_action_for @region, {
  #       diff: {
  #         property_ids: [[], [@property.id]]
  #       },
  #       subject_type: "Region",
  #       subject_id: @region.id,
  #       timestamp: @time.iso8601(3),
  #       type: 'update'
  #     }
  #   end
  # end

  # test '::update with removing has_and_belongs_to_many association' do
  #   @property = create(:property)
  #   @region = create(:region, properties: [@property])
  #   WebMock::RequestRegistry.instance.reset!
    
  #   travel_to(@time) { @region.update(properties: []) }

  #   assert_posted("/events") do
  #     assert_action_for @region, {
  #       diff: {
  #         property_ids: [[@property.id], []]
  #       },
  #       subject_type: "Region",
  #       subject_id: @region.id,
  #       timestamp: @time.iso8601(3),
  #       type: 'update'
  #     }

  #     assert_action_for @property, {
  #       timestamp: @time.iso8601(3),
  #       type: 'update',
  #       subject_type: "Property",
  #       subject_id: @property.id,
  #       diff: {
  #         region_ids: [[@region.id], []]
  #       }
  #     }
  #   end
  # end
  
  # test '::update with replacing has_and_belongs_to_many association' do
  #   @property1 = create(:property)
  #   @property2 = create(:property)
  #   @region = create(:region, properties: [@property1])
  #   WebMock::RequestRegistry.instance.reset!
    
  #   travel_to(@time) { @region.update(properties: [@property2]) }

  #   assert_posted("/events") do
  #     assert_action_for @region, {
  #       diff: {
  #         property_ids: [[@property1.id], [@property2.id]]
  #       },
  #       subject_type: "Region",
  #       subject_id: @region.id,
  #       timestamp: @time.iso8601(3),
  #       type: 'update'
  #     }

  #     assert_action_for @property1, {
  #       timestamp: @time.iso8601(3),
  #       type: 'update',
  #       subject_type: "Property",
  #       subject_id: @property1.id,
  #       diff: {
  #         region_ids: [[@region.id], []]
  #       }
  #     }

  #     assert_action_for @property2, {
  #       timestamp: @time.iso8601(3),
  #       type: 'update',
  #       subject_type: "Property",
  #       subject_id: @property2.id,
  #       diff: {
  #         region_ids: [[], [@region.id]]
  #       }
  #     }
  #   end
  # end
  
  # test '::destroying updates has_and_belongs_to_many associations' do
  #   @property = create(:property)
  #   @region = create(:region, properties: [@property])
  #   WebMock::RequestRegistry.instance.reset!
    
  #   travel_to(@time) { @region.destroy }

  #   assert_posted("/events") do
  #     assert_action_for @region, {
  #       diff: {
  #         id: [@region.id, nil],
  #         name: [@region.name, nil],
  #         property_ids: [[@property.id], []]
  #       },
  #       subject_type: "Region",
  #       subject_id: @region.id,
  #       timestamp: @time.iso8601(3),
  #       type: 'destroy'
  #     }.as_json

  #     assert_action_for @property, {
  #       timestamp: @time.iso8601(3),
  #       type: 'update',
  #       subject_type: "Property",
  #       subject_id: @property.id,
  #       diff: {
  #         region_ids: [[@region.id], []]
  #       }
  #     }.as_json
  #   end
  # end

  # test 'has_and_belongs_to_many <<'
  # test 'has_and_belongs_to_many.delete'
  # test 'has_and_belongs_to_many.destroy'
  # test 'has_and_belongs_to_many='

  test 'has_and_belongs_to_many_ids=' do
    @parent = create(:region)
    puts "PARENT: #{@parent.id}"
    @child = create(:region)
    puts "CHILD: #{@child.id}"
    WebMock::RequestRegistry.instance.reset!
    
    travel_to(@time) { @child.parent_ids = [@parent.id] }

    assert_posted("/events") do
      assert_action_for @child, {
        diff: {
          parent_ids: [[], [@parent.id]]
        },
        subject_type: "Region",
        subject_id: @child.id,
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json

      assert_action_for @parent, {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Region",
        subject_id: @parent.id,
        diff: {
          child_ids: [[], [@child.id]]
        }
      }.as_json
    end
  end
  
  # test 'has_and_belongs_to_many.clear'
  # test 'has_and_belongs_to_many.create'
  
end