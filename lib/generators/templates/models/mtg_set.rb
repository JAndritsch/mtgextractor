class MtgSet < ActiveRecord::Base
  has_many :mtg_cards
  validates :name, :uniqueness => true, :presence => true

  alias_method :cards, :mtg_cards

  def folder_name
    name.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  end

  def common_icon
    "/assets/images/#{folder_name}/common_icon.jpg"
  end

  def uncommon_icon
    "/assets/images/#{folder_name}/uncommon_icon.jpg"
  end

  def rare_icon
    "/assets/images/#{folder_name}/rare_icon.jpg"
  end

  def mythic_icon
    "/assets/images/#{folder_name}/mythic_icon.jpg"
  end

end

