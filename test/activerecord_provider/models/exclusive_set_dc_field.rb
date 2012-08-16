class ExclusiveSetDCField < ActiveRecord::Base
  inheritance_column = 'DONOTINHERIT'

  def self.sets
    klass = Struct.new(:name, :spec)
    self.uniq.pluck('`set`').compact.map do |spec|
      klass.new("Set #{spec}", spec)
    end
  end

end
