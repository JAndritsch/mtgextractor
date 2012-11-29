class CreateMtgCardsMtgSets < ActiveRecord::Migration
  def self.up
    create_table :mtg_cards_mtg_sets do |t|
      t.references :mtg_set
      t.references :mtg_card
      t.timestamps
    end
  end

  def self.down
    drop_table :mtg_cards_mtg_sets
  end
end
