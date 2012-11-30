class CreateMtgTypes < ActiveRecord::Migration
  def self.up
    create_table :mtg_types do |t|
      t.string     :name
      t.timestamps
    end
  end

  def self.down
    drop_table :mtg_types
  end
end
