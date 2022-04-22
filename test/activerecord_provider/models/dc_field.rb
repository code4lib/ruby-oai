class DCField < ActiveRecord::Base
  self.inheritance_column = 'DONOTINHERIT'
  has_and_belongs_to_many :sets,
    :join_table => "dc_fields_dc_sets",
    :foreign_key => "dc_field_id",
    :class_name => "DCSet"

  belongs_to :dc_lang, class_name: "DCLang", optional: true

  default_scope -> { left_outer_joins(:dc_lang) }

  def language
    dc_lang&.name
  end
end
