require 'test_helper'

class CreateTest < ActiveSupport::TestCase
  
  def setup
    super
    @time = Time.now.utc.change(usec: 0)
  end
  
  test '::create creates an Action' do
    @property = travel_to(@time) { create(:property) }
    
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 1, req_data['actions'].size
      
      assert_equal req_data['actions'][0], {
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
        subject_id: @property.id,
        subject_type: 'Property',
        timestamp: @time.iso8601(3),
        type: 'create'
      }.as_json
    end
  end
  
  test "::create creates an Action without :excluded attributes" do
    @comment = travel_to(@time) { create(:comment) }
    
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 1, req_data['actions'].size
      
      assert_equal req_data['actions'][0], {
        diff: {
          id: [nil, @comment.id],
          # No Title
          body: [nil, @comment.body]
        },
        subject_id: @comment.id,
        subject_type: 'Comment',
        timestamp: @time.iso8601(3),
        type: 'create'
      }.as_json
    end
  end
  
  
end


