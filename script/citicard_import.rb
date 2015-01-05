#!/usr/bin/env rails runner

importer = Service::CiticardImporter.new(ARGF)
importer.import
if importer.errors?
  STDERR.puts "Found #{importer.errors.size} errors during import:\n"
  STDERR.puts importer.format_errors
  STDERR.puts "Imported #{importer.imported.size} transactions"
  exit 1
end
puts("Imported #{importer.imported.size} transactions")
