class CreateTxnImporterFactories < ActiveRecord::Migration
  def change
    create_table :txn_importer_factories do |t|
      t.text :memo_regexp, null: false
      t.references :user, null: false
      t.references :payee, null: false
      t.references :from_account, null: false
      t.references :to_account, null: false

      t.timestamps
    end
    add_index :txn_importer_factories, :user_id
    add_index :txn_importer_factories, :payee_id
    add_index :txn_importer_factories, :from_account_id
    add_index :txn_importer_factories, :to_account_id
  end
end
