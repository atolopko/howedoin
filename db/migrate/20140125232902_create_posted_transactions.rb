class CreatePostedTransactions < ActiveRecord::Migration
  def change
    create_table :posted_transactions do |t|
      t.timestamps
      t.date :sale_date
      t.date :post_date
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.text :reference_identifier
      t.text :type_identifier
      t.text :category
      t.text :memo
      t.text :person

      t.references :account, null: false
      # t.references :txn, null: false
    end
  end
end
