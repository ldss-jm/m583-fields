require 'marc'

# Creates a MARC::DataField representing a retention 583.
#
# @example Scholars Trust
#   Retention583.new(constants).marc.to_mrk
#     #=> =583  1\|acommitted to retain|c20190701|d20351231|fScholars Trust|5NcU
# @example TRLN Collaborative Print Retention
#   Retention583.new(constants).marc.to_mrk
#     #=> =583  1\|acommitted to retain|c20190701|dretention period not specified|fTRLN Collaborative Print Retention|5NcU
class Retention583
  attr_accessor :action, :action_date, :action_interval, :programs, :institution

  def initialize(constants = {})
    @action = constants[:action]
    @action_date = constants[:action_date]
    @action_interval = constants[:action_interval]
    @programs = constants[:programs]
    @institution = constants[:institution]
  end

  # @return [MARC::DataField] retention 583 MARC field
  def marc
    # ind1=1 means 583 is not private
    rec = MARC::DataField.new('583', '1', ' ')
    rec.append MARC::Subfield.new('a', @action)
    rec.append MARC::Subfield.new('c', @action_date)
    rec.append MARC::Subfield.new('d', @action_interval)
    rec.append MARC::Subfield.new('f', @programs)
    rec.append MARC::Subfield.new('5', @institution)
    rec
  end
end
