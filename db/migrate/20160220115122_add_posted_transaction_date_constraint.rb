class AddPostedTransactionDateConstraint < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE posted_transactions ADD CONSTRAINT sale_date_or_post_date_not_null CHECK (sale_date IS NOT NULL OR post_date IS NOT NULL);
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE posted_transactions DROP CONSTRAINT sale_date_or_post_date_not_null;
    SQL
  end
end
