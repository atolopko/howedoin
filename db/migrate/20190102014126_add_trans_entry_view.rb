class AddTransEntryView < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE VIEW trans_entry AS SELECT t.date, t.payee_id, p.name payee_name, e.*, a.name account_aname FROM transaction t JOIN payee p ON (t.payee_id = p.payee_id) JOIN entry e ON (t.trans_id = e.trans_id) JOIN account a ON (e.acct_id = a.acct_id) WHERE NOT is_void;
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW trans_entry;
    SQL
  end
end
