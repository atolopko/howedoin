class TxnImporterFactoryPayeeDropNotNull < ActiveRecord::Migration
  def up
    execute <<-SQL
      alter table txn_importer_factories alter column payee_id drop not null;
    SQL
  end

  def down
    execute <<-SQL
      alter table txn_importer_factories alter column payee_id set not null;
    SQL
  end
end
