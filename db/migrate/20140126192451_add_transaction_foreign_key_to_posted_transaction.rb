class AddTransactionForeignKeyToPostedTransaction < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE posted_transactions ADD COLUMN txn_id int REFERENCES transaction (trans_id);
      ALTER TABLE posted_transactions ADD CONSTRAINT posted_transactions_uniq_txn_id UNIQUE (txn_id);
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE posted_transactions DROP COLUMN txn_id;
    SQL
  end
end

