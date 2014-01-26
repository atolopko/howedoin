class AddPostedTransactionForeignKeys < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE posted_transactions ADD CONSTRAINT posted_transactions_account_fk FOREIGN KEY (account_id) REFERENCES account (acct_id);
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE posted_transactions DROP CONSTRAINT posted_transactions_account_fk;
    SQL
  end
end
