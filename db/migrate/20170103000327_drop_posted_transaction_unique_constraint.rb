class DropPostedTransactionUniqueConstraint < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE posted_transactions DROP CONSTRAINT posted_transactions_uniq_txn_id;
    SQL
  end

  def down
    execute <<-SQL
      CREATE UNIQUE INDEX ON posted_transactions (txn_id, account_id);
      ALTER TABLE posted_transactions CREATE CONSTRAINT UNIQUE USING INDEX posted_transactions_uniq_txn_id;
    SQL
  end
end
