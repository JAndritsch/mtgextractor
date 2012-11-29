class Card < ActiveRecord::Base
  belongs_to :set
  validates :name, :presence => true
  validates :set,  :presence => true
end
