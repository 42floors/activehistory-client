ActiveRecord::Schema.define do

  create_table "accounts", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.integer  'photos_count', null: false, default: 0
  end
  
  create_table "email_addresses", force: :cascade do |t|
    t.string   "address",      limit: 255
    t.integer  'account_id'
  end
    
  create_table "photos", force: :cascade do |t|
    t.integer  "account_id"
    t.integer  "property_id"
    t.string   "format",                 limit: 255
  end
  
  create_table "photos_properties", id: false, force: :cascade do |t|
    t.integer "property_id", null: false
    t.integer "photo_id",  null: false
  end
    
  create_table "properties", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.string   "aliases",              default: [],   array: true
    t.text     "description"
    t.integer  "constructed"
    t.decimal  "size"
    # t.json     "amenities",                     default: {}, null: false
    t.datetime "created_at",                         null: false
    # t.geometry "location",             limit: {:type=>"Point", :srid=>"4326"}
    t.boolean  "active",             default: false
  end

  create_table "regions", force: :cascade do |t|
    t.string  "name",                 limit: 255
  end
    
  create_table "properties_regions", id: false, force: :cascade do |t|
    t.integer "property_id", null: false
    t.integer "region_id",  null: false
  end
    
  create_table "regions_regions", id: false, force: :cascade do |t|
    t.integer "parent_id", null: false
    t.integer "child_id",  null: false
  end
  
  create_table "comments", force: :cascade do |t|
    t.string 'title', limit: 255
    t.text 'body', null: false
  end
  
  create_table "unobserved_models", force: :cascade do |t|
    t.text "body"
  end

end