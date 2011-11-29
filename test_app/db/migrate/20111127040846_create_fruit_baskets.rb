class CreateFruitBaskets < ActiveRecord::Migration
  def change
    create_table :fruit_baskets do |t|
      t.integer :fruit_id
      t.integer :basket_id
      t.timestamps
    end
  end
end
