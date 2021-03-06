class Account < ActiveRecord::Base
  
  track
  
  has_many :photos
  has_many :comments
  has_one :email_address
  
end

class EmailAddress < ActiveRecord::Base
  
  track
  
  belongs_to :account, inverse_of: :email_address
  
end

class Photo < ActiveRecord::Base

  track
    
  belongs_to :account, counter_cache: true, inverse_of: :photos
  belongs_to :property, inverse_of: :photos

end

class Property < ActiveRecord::Base

  track
  
  has_many :photos, inverse_of: :property

  has_and_belongs_to_many :regions, inverse_of: :properties
  has_and_belongs_to_many :attachments, class_name: 'Photo'
end

class Region < ActiveRecord::Base

  track
  
  has_and_belongs_to_many :properties, inverse_of: :regions

  has_and_belongs_to_many :parents,
    class_name: 'Region',
    join_table: 'regions_regions',
    foreign_key: 'child_id',
    association_foreign_key: 'parent_id',
    inverse_of: :children

  has_and_belongs_to_many :children,
    class_name: 'Region',
    join_table: 'regions_regions',
    foreign_key: 'parent_id',
    association_foreign_key: 'child_id',
    inverse_of: :parents

end

class Comment < ActiveRecord::Base
  
  track exclude: :title
  
  belongs_to :account
  
end

class UnobservedModel < ActiveRecord::Base
  
end

class UnobservedComment < Comment
  
  track false
  
end
