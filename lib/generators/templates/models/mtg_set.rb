class MtgSet < ActiveRecord::Base
  has_many :mtg_cards
  validates :name, :uniqueness => true, :presence => true

  alias_method :cards, :mtg_cards

  def folder_name
    name.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  end

end

