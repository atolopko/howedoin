class AddPostedTransactionForeignKeys < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE posted_transactions ADD CONSTRAINT posted_transactions_account_fk FOREIGN KEY (account_id) REFERENCES account (acct_id);
      -- ALTER TABLE posted_transactions ADD CONSTRAINT posted_transactions_transaction_fk FOREIGN KEY (txn_id) REFERENCES transaction (trans_id);
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE posted_transactions DROP CONSTRAINT posted_transactions_account_fk;
      -- ALTER TABLE posted_transactions DROP CONSTRAINT posted_transactions_transaction_fk;
    SQL
  end
end
