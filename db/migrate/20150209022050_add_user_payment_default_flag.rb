class AddUserPaymentDefaultFlag < ActiveRecord::Migration
  def up
    execute <<-SQL
      alter table fuser add column payment_default boolean not null default false;
      alter table fuser add exclude (payment_default with =) where (payment_default = true);
    SQL
  end

  def down
    execute <<-SQL
      alter table fuser drop column payment_default;
    SQL
  end
end
