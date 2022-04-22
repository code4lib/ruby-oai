class ExclusiveSetDCField < ActiveRecord::Base
  self.inheritance_column = 'DONOTINHERIT'

  def self.sets
    klass = Struct.new(:name, :spec)
    self.distinct.pluck(:set).compact.map do |spec|
      klass.new("Set #{spec}", spec)
    end
  end

  belongs_to :dc_lang, class_name: "DCLang", optional: true

  def language
    dc_lang&.name
  end

end
