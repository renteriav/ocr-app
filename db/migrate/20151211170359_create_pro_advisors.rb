class CreateProAdvisors < ActiveRecord::Migration
  def change
    create_table :pro_advisors do |t|
      t.string :first
      t.string :last
      t.string :company_name
      t.string :email
      t.string :phone
      t.string :address
      t.string :city
      t.string :state
      t.string :zip_code

      t.timestamps null: false
    end
  end
end
