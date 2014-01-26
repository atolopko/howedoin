Notes:

When importing legacy database into howedoin dev db, execute SQL 'drop
extension plpgsql cascade' to allow 'rake db:test:clone_structure' to work;
otherwise the dumped structure.sql attempted to add a comment to the plpgsql
extension, which is it does not have permissions to do as user the db user
'howedoin'.

Must use 'rake db:test_clone_structure' instead of 'rake db:test:prepare'
since schema.rb does not support PG enum types and some table creations fail
due to this.
