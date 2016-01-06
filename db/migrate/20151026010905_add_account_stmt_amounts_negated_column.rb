class AddAccountStmtAmountsNegatedColumn < ActiveRecord::Migration
  def up
    execute <<-SQL
      alter table account add column stmt_amounts_negated boolean default false not null;
    SQL
  end

  def down
    execute <<-SQL
      alter table account drop column stmt_amounts_negated;
    SQL
  end
end
