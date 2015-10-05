class TxnImporterFactoryMinAndMaxAmounts < ActiveRecord::Migration
  def up
    execute <<-SQL
      alter table txn_importer_factories add column min_amount numeric(10,2);
      alter table txn_importer_factories add column max_amount numeric(10,2);
    SQL
  end

  def down
    execute <<-SQL
      alter table txn_importer_factories drop column min_amount;
      alter table txn_importer_factories drop column max_amount;
    SQL
  end
end
