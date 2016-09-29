require 'test_helper'

class HasOneAssociationTest < ActiveSupport::TestCase
  
  def setup
    super
    @time = (Time.now.utc + 2).change(usec: 0)
  end

  test '::create with has_one association' do
    @email_address = create(:email_address)
    WebMock::RequestRegistry.instance.reset!
    
    @account = travel_to(@time) { create(:account, email_address: @email_address) }
    
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size
      
      assert_equal req_data['actions'][0], {
        diff: {
          id: [nil, @account.id],
          name: [nil, @account.name],
          photos_count: [nil, 0],
          email_address_id: [nil, @email_address.id]
        },
        subject_id: @account.id,
        subject_type: 'Account',
        timestamp: @time.iso8601(3),
        type: 'create'
      }.as_json

      assert_equal req_data['actions'][1], {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_id: @email_address.id,
        subject_type: 'EmailAddress',
        diff: {
          account_id: [nil, @account.id]
        }
      }.as_json
    end
  end
    
  test '::create with belongs_to association' do
    @account = create(:account)
    WebMock::RequestRegistry.instance.reset!
    
    @email_address = travel_to(@time) { create(:email_address, account: @account) }
    
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size
      
      assert_equal req_data['actions'][0], {
        diff: {
          id: [nil, @email_address.id],
          address: [nil, @email_address.address],
          account_id: [nil, @account.id]
        },
        subject_id: @email_address.id,
        subject_type: 'EmailAddress',
        timestamp: @time.iso8601(3),
        type: 'create'
      }.as_json

      assert_equal req_data['actions'][1], {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_id: @account.id,
        subject_type: 'Account',
        diff: {
          email_address_id: [nil, @email_address.id]
        }
      }.as_json
    end
  end
  
  test '::create with has_one association 2' do
    @account = travel_to(@time) { create(:account, email_address: build(:email_address)) }
    
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size
      
      assert_equal req_data['actions'][0], {
        diff: {
          id: [nil, @account.id],
          name: [nil, @account.name],
          photos_count: [nil, 0],
          email_address_id: [nil, @account.email_address.id]
        },
        subject_id: @account.id,
        subject_type: 'Account',
        timestamp: @time.iso8601(3),
        type: 'create'
      }.as_json

      assert_equal req_data['actions'][1], {
        timestamp: @time.iso8601(3),
        type: 'create',
        subject_id: @account.email_address.id,
        subject_type: 'EmailAddress',
        diff: {
          id: [nil, @account.email_address.id],
          address: [nil, @account.email_address.address],
          account_id: [nil, @account.id]
        }
      }.as_json
    end
  end
  
  test '::update removes has_one association' do
    @account = create(:account, email_address: build(:email_address))
    WebMock::RequestRegistry.instance.reset!

    @email_address = @account.email_address
    travel_to(@time) { @account.update(email_address: nil) }
    
    assert_posted("/events") do |req|
      req_data = JSON.parse(req.body)
      assert_equal 2, req_data['actions'].size
      
      assert_equal req_data['actions'][0], {
        diff: {
          account_id: [@account.id, nil]
        },
        subject_id: @email_address.id,
        subject_type: 'EmailAddress',
        timestamp: @time.iso8601(3),
        type: 'update'
      }.as_json

      assert_equal req_data['actions'][1], {
        timestamp: @time.iso8601(3),
        type: 'update',
        subject_id: @account.id,
        subject_type: 'Account',
        diff: {
          email_address_id: [@email_address.id, nil]
        }
      }.as_json
    end
  end

  test '::destroy removes has_one association with dependent: :nullify'
  test '::destroy removes has_one association with dependent: :delete'
  
end