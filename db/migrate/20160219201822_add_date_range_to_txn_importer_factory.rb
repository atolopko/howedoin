class AddDateRangeToTxnImporterFactory < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE txn_importer_factories ADD COLUMN min_date DATE;
      ALTER TABLE txn_importer_factories ADD COLUMN max_date DATE;
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE txn_importer_factories DROP COLUMN min_date;
      ALTER TABLE txn_importer_factories DROP COLUMN max_date;
    SQL
  end
end
