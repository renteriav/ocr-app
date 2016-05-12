class CreateRuleDetails < ActiveRecord::Migration
  def change
    create_table :rule_details do |t|
      t.references :rule
      t.integer :code
      t.string :value
      t.timestamps
    end
  end
end
