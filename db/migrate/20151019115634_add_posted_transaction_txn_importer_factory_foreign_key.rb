class AddPostedTransactionTxnImporterFactoryForeignKey < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE posted_transactions ADD COLUMN txn_importer_factory_id int REFERENCES txn_importer_factories;
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE posted_transactions DROP COLUMN txn_importer_factory_id;
    SQL
  end
end
