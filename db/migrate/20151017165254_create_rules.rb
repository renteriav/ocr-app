class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.references :user
      t.string :name
      t.boolean :is_qb_rule
      t.boolean :is_and_rule
      t.string :memo
      t.string :payee
      t.string :category
      t.integer :transfer_account_id
      t.timestamps
    end
  end
end
