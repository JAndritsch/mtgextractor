class CreateMtgCardTypes < ActiveRecord::Migration
  def self.up
    create_table :mtg_card_types do |t|
      t.references :mtg_card
      t.references :mtg_type
      t.timestamps
    end
  end

  def self.down
    drop_table :mtg_card_types
  end
end
