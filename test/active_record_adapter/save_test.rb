require 'test_helper'

class SaveTest < ActiveSupport::TestCase
  
  def setup
    super
    @time = (Time.now.utc + 2).change(usec: 0)
  end
  
  test '::save creates an Action' do
    @property = create(:property, name: 'unkown')
    WebMock::RequestRegistry.instance.reset!
    
    @property.name = 'Empire State Building'
    travel_to(@time) { @property.save }
    
    assert_posted("/events") do
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
  end
  
  test '::save creates an Action, excluding any :excluded attributes' do
    @comment = create(:comment, title: 'title', body: 'body')
    WebMock::RequestRegistry.instance.reset!
    
    @comment.title = 'new title'
    @comment.body = 'new body'
    travel_to(@time) { @comment.save }
    
    assert_posted("/events") do
      assert_action_for @comment, {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_type: "Comment",
        subject_id: @comment.id,
        diff: {
          body: ['body', 'new body']
        }
      }.as_json
    end
  end
  
  test "::save doesn't create an Action if just changing :excluded attributes" do
    @comment = create(:comment, title: 'title', body: 'body')
    WebMock::RequestRegistry.instance.reset!

    @comment.title = 'new title'
    travel_to(@time) { @comment.save }
    
    assert_not_posted("/events")
  end
  
end


