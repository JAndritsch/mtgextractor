class Set < ActiveRecord::Base
  has_many :cards
  validates :name, :uniqueness => true, :presence => true
end

