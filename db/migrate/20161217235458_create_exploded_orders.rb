class CreateExplodedOrders < ActiveRecord::Migration
  def change
    create_table :exploded_orders do |t|
      t.integer :shopify_id, limit: 8
      t.timestamps(null: false)
    end
  end
end
