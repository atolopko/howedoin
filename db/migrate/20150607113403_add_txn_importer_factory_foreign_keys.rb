class AddTxnImporterFactoryForeignKeys < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE txn_importer_factories ADD CONSTRAINT t_i_f_user_fk FOREIGN KEY (user_id) REFERENCES fuser (user_id);
      ALTER TABLE txn_importer_factories ADD CONSTRAINT t_i_f_payee_fk FOREIGN KEY (payee_id) REFERENCES payee (payee_id);
      ALTER TABLE txn_importer_factories ADD CONSTRAINT t_i_f_to_account_fk FOREIGN KEY (to_account_id) REFERENCES account (acct_id);
      ALTER TABLE txn_importer_factories ADD CONSTRAINT t_i_f_from_account_fk FOREIGN KEY (from_account_id) REFERENCES account (acct_id);
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE txn_importer_factories DROP CONSTRAINT t_i_f_user_fk;
      ALTER TABLE txn_importer_factories DROP CONSTRAINT t_i_f_payee_fk;
      ALTER TABLE txn_importer_factories DROP CONSTRAINT t_i_f_to_account_fk;
      ALTER TABLE txn_importer_factories DROP CONSTRAINT t_i_f_from_account_fk;
    SQL
  end
end
