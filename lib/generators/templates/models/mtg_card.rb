class MtgCard < ActiveRecord::Base
  belongs_to :mtg_set
  validates :name, :presence => true
  validates :mtg_set,  :presence => true
end
