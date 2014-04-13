class CreateMtgCards < ActiveRecord::Migration
  def self.up
    create_table :mtg_cards do |t|
      t.string     :name
      t.string     :gatherer_url
      t.string     :multiverse_id
      t.string     :gatherer_image_url
      t.string     :mana_cost
      t.string     :converted_cost
      t.text       :oracle_text
      t.text       :flavor_text
      t.string     :mark
      t.string     :power
      t.string     :toughness
      t.string     :loyalty
      t.string     :rarity
      t.string     :transformed_id
      t.string     :colors
      t.string     :artist
      t.references :mtg_set
      t.timestamps
    end
  end

  def self.down
    drop_table :mtg_cards 
  end

end
