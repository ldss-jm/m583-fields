# This script will:
#   indicate which holdings records can have a 583$3 copied directly from an 866$a
#   for the other records, generate global update save files that will
#     load  583$3's individualized for each record
#   indicate which holdings records will need a missing issues 583$l

require 'sierra_postgres_utilities'
require 'global_update_command_writer_iii_doesnt_want_you_to_know_about'

require_relative 'completeness_583.rb'
require_relative 'retention_583.rb'

# We do want this to literally be "YYYYMMDD"; it's used in multiple fields and
# we'll change it to a date with Sierra global update
date_of_action = 'YYYYMMDD'

# We don't need to care about these retention 583s here. They're static
# and directly added to the hrecs in Sierra global update.
#
# scholars = Retention583.new
# scholars.programs = 'Scholars Trust'
# scholars.action_interval = '20351231'
#
# scholars.action = 'committed to retain'
# scholars.action_date = date_of_action
# scholars.institution = 'NcU'
#
# trln = Retention583.new
# trln.programs = 'TRLN Collaborative Print Retention'
# trln.action_interval = 'retention period not specified'
#
# trln.action = 'committed to retain'
# trln.action_date = date_of_action
# trln.institution = 'NcU'

completeness_constants = {
  institution: 'NcU',
  action: 'completeness reviewed',
  action_date: date_of_action,
  validation_level: 'issue-level validation',
  programs: ['Scholars Trust', 'TRLN Collaborative Print Retention']
}

# set list number containing holdings records needing 583s
list_num = 76

crecs = Sierra::Data::CreateList.get(list_num).records

# ensure 583s don't already exist
# if they do, presumably check to make sure we need to add all three 583s.
crecs.select { |rec| rec.marc['583'] }.each { |rec| puts "#{rec.rnum} has a 583" }

# This file will contain rnums where we can just duplicate the 866 into a 583
exact = File.open('exact_866_duplication.txt', 'w')

# This file will contain rnums where we'll need to use global update save files
inexact = File.open('inexact_modify_001_dupe.txt', 'w')

# This file will contain rnums where we'll later need to add a "missing issues" $l
incomplete = File.open('cnums_need_missing_subfield.txt', 'w')

inexact_recs = []

crecs.each do |rec|
  completeness = Completeness583.new(rec, completeness_constants)

  if rec.marc['866'] && completeness.marc['3'] == rec.marc['866']['a']
    # One of the global updates will delete from the copy of the 866
    # any $8s and $6s. We need to know if there are any other non-$a subfields
    # so that they can be deleted to.
    if (rec.marc['866'].subfields.map(&:code) - ['a', '8', '6']).any?
      puts "WARN: #{rec.rnum} has 866 subfields that need to be deleted (in " \
           "the duplicated field) during global update"
    end
    exact << "#{rec.rnum}\n"
  else
    inexact << "#{rec.rnum}\n"
    inexact_recs << rec
  end

  incomplete << "#{rec.rnum}\n" if completeness.marc['l']
end
exact.close
inexact.close
incomplete.close

# Write the global update save files
cw = CommandWriter.new(recs: inexact_recs, rectype: 'holdings',
                       filestem: 'm583_updates', keyfield: '001')
cw.write_command do |rec|
  completeness = Completeness583.new(rec, completeness_constants)
  "|3#{completeness.m583sf3}"
end
