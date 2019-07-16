# m583-fields

Ruby models of retention and completeness 583s and a script to create them
in Sierra (III ILS) from 866/867/868 data.

Usage details on internal staff wiki:
  <https://internal.lib.unc.edu/wikis/staff/index.php/Batch_add_retention_583s>

Some general 583 info (which we don't wholly follow):
  <http://www.aserl.org/programs/j-retain/standards-for-use-of-the-marc-583-field/>

## Requirements

- [sierra_postgres_utilities](https://github.com/UNC-Libraries/sierra-postgres-utilities) gem
- [global_update_command_writer_iii_doesnt_want_you_to_know_about](https://github.com/ldss-jm/global-update-command-writer-iii-doesnt-want-you-to-know-about) gem
