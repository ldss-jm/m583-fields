require 'sierra_postgres_utilities'
require 'marc'

# Creates a MARC::DataField representing a retention 583.
#
# The MARC field uses indicators "99" rather than "1 " to identify the record;
# these values need to be updated in Sierra afterward.
#
# @example when holdings do NOT have gaps / missing issues
#   Completeness583.new(hrec, constants).marc.to_mrk
#     #=> =583  1\$3v.1-v.3; Supplement: v.1-v.3; Index: v.1/3$acompleteness reviewed$c20190701$fScholars Trust$fTRLN Collaborative Print Retention$iitem-level validation$lmissing issues$5NcU
# @example when holdings have gaps / missing issues
#   Completeness583.new(hrec, constants).marc.to_mrk
#     #=> =583  1\$3v.1-v.3, v.5-6$acompleteness reviewed$c20190701$fScholars Trust$fTRLN Collaborative Print Retention$iitem-level validation$lmissing issues$5NcU
class Completeness583
  attr_reader :hrec
  attr_accessor :action, :action_date, :action_interval, :programs, :institution

  # @param holdings_record [Sierra::Data::Holdings] holdings record
  # @param constants [Hash] contains constant data used to populate 583
  #   subfields. Constant data can be set post-init if desired.
  def initialize(holdings_record, constants = {})
    @hrec = holdings_record
    @action = constants[:action]
    @action_date = constants[:action_date]
    @action_interval = constants[:action_interval]
    @programs = [constants[:programs]].flatten
    @validation_level = constants[:validation_level]
    @institution = constants[:institution]
  end

  # @return [Sierra::Data::Bib] the holdings record's bib record
  def bib
    hrec.first.bib
  end

  # @return [MARC::DataField] completeness 583 MARC field
  def marc
    # The proper indicators are "1 "
    #   ind1=1 means 583 is not private
    # We instead use "99" so that we can identify/manipulate the field in Sierra.
    # But it needs to be changed in Sierra to "1 " afterward.
    rec = MARC::DataField.new('583', '9', '9')
    rec.append MARC::Subfield.new('3', m583sf3)
    rec.append MARC::Subfield.new('a', @action)
    rec.append MARC::Subfield.new('c', @action_date)
    @programs.each { |p| rec.append MARC::Subfield.new('f', p) }
    rec.append MARC::Subfield.new('i', @validation_level)
    rec.append m583sfl if gaps?
    rec.append MARC::Subfield.new('5', @institution)
    rec
  end

  private

  # @param marc_tag [String] the marc_tag for the field to process (the first $a
  #   of each instance of that field will be processed)
  # @return [Array<String>] $a values (with trailing commas stripped) for
  #   specified field
  def field_to_holdings(marc_tag)
    hrec.marc.fields(marc_tag).map { |f| f['a'].sub(/[\s,]*$/, '') }
  end

  # @return [String] $3 contents for the 583
  # @example
  #   #=> 'v.1-v.10; Supplement v.1-v.10; Index v.1/10'
  def m583sf3
    sf3 = field_to_holdings('866').join(', ')

    m867s = field_to_holdings('867').join(', ')
    sf3 += "; Supplement: #{m867s}" unless m867s.empty?

    m868s = field_to_holdings('868').join(', ')
    sf3 += "; Index: #{m868s}" unless m868s.empty?

    # fix beginning if there are no 866 holdings
    sf3.gsub!(/^; /, '')
    sf3
  end

  # @return [Boolean] whether any of the 866/867/868 $a include (non-trailing)
  #   commas, which we take to represent gaps / missing issues
  def gaps?
    (
      field_to_holdings('866').join.include?(',') ||
      field_to_holdings('867').join.include?(',') ||
      field_to_holdings('868').join.include?(',')
    )
  end

  # @return [nil, MARC::DataField] subfield l/ell value when holdings have gaps;
  #   nil otherwise
  # @example holdings have gaps
  #   #=> #<MARC::Subfield:0x0000000349f040 @code="l", @value="missing issues">
  def m583sfl # ell
    return unless gaps?

    MARC::Subfield.new('l', 'missing issues')
  end
end
