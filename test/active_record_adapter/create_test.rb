require 'test_helper'

class CreateTest < ActiveSupport::TestCase
  
  def setup
    super
    @time = Time.now.utc.change(usec: 0)
  end
  
  test '::create creates an Action' do
    @property = travel_to(@time) { create(:property) }
    
    assert_posted("/events") do      
      assert_action_for @property, {
        diff: {
          id: [nil, @property.id],
          name: [nil, @property.name],
          aliases: [nil, []],
          description: [nil, @property.description],
          constructed: [nil, @property.constructed],
          size: [nil, @property.size],
          active: [nil, @property.active],
          created_at: [nil, @property.created_at]
        },
        subject_type: "Property",
        subject_id: @property.id,
        timestamp: @time.iso8601(3),
        type: 'create'
      }
    end
  end
  
  test "::create creates an Action without :excluded attributes" do
    @comment = travel_to(@time) { create(:comment) }
    
    assert_posted("/events") do      
      assert_action_for @comment, {
        diff: {
          id: [nil, @comment.id],
          # No Title
          body: [nil, @comment.body]
        },
        subject_type: "Comment",
        subject_id: @comment.id,
        timestamp: @time.iso8601(3),
        type: 'create'
      }
    end
  end
  
  
end


