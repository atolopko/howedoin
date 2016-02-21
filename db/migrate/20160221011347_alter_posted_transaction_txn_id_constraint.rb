class AlterPostedTransactionTxnIdConstraint < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE posted_transactions DROP CONSTRAINT posted_transactions_uniq_txn_id;
      ALTER TABLE posted_transactions ADD CONSTRAINT posted_transactions_uniq_txn_id UNIQUE (txn_id, account_id);
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE posted_transactions DROP CONSTRAINT posted_transactions_uniq_txn_id;
      ALTER TABLE posted_transactions ADD CONSTRAINT posted_transactions_uniq_txn_id UNIQUE (txn_id);
    SQL
  end
end
