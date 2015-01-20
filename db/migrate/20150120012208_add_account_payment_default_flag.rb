class AddAccountPaymentDefaultFlag < ActiveRecord::Migration
  def up
    execute <<-SQL
      alter table account add column payment_default boolean check (payment_default = false OR acct_type in ('asset', 'liability'));
      alter table account add exclude (payment_default with =) where (payment_default = true);
    SQL
  end

  def down
    execute <<-SQL
      alter table account drop column payment_default;
    SQL
  end
end
