class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.text :name
      t.text :number
      t.text :description
      t.date :opened_on
      t.boolean :closed
      t.date :closed_on

      t.timestamps
    end
  end
end
