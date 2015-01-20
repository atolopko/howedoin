#!/usr/bin/env rails runner

begin
  Account.transaction do
    balance = BigDecimal.new(ARGV.pop)
    stmt_date = Date.parse(ARGV.pop)
    account = Account.where("name like 'Citibank MasterCard%'").last!
    statement = account.statements.create!(stmt_date: stmt_date, balance: balance)
    importer = Service::CiticardImporter.new(ARGF, statement)
    importer.import
    if importer.errors?
      STDERR.puts "Found #{importer.errors.size} errors during import:\n"
      STDERR.puts importer.format_errors
      STDERR.puts "Imported #{importer.imported.size} transactions"
      raise ActiveRecord::Rollback
    end
    puts("Imported #{importer.imported.size} transactions")
  end
rescue StandardError => e
  ap e
end
