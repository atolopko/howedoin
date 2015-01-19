class AddStatementToPostedTransactions < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE posted_transactions ADD COLUMN stmt_id int NOT NULL REFERENCES bankstatement (stmt_id);
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE posted_transactions DROP COLUMN stmt_id;
    SQL
  end
end
