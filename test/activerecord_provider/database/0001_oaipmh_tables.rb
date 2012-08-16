class OaipmhTables < ActiveRecord::Migration
  def self.up
    create_table :oai_tokens do |t|
      t.column :token,      :string,  :null => false
      t.column :created_at, :timestamp
    end

    create_table :oai_entries do |t|
      t.column :record_id, :integer, :null => false
      t.column :oai_token_id, :integer, :null => false
    end

    dc_fields = proc do |t|
      t.column  :title,         :string
      t.column  :creator,       :string
      t.column  :subject,       :string
      t.column  :description,   :string
      t.column  :contributor,   :string
      t.column  :publisher,     :string
      t.column  :date,          :datetime
      t.column  :type,          :string
      t.column  :format,        :string
      t.column  :source,        :string
      t.column  :language,      :string
      t.column  :relation,      :string
      t.column  :coverage,      :string
      t.column  :rights,        :string
      t.column  :updated_at,    :datetime
      t.column  :created_at,    :datetime
      t.column  :deleted,       :boolean,   :default => false
    end

    create_table :exclusive_set_dc_fields do |t|
      dc_fields.call(t)
      t.column  :set,           :string
    end

    create_table :dc_fields, &dc_fields

    create_table :dc_fields_dc_sets, :id => false do |t|
      t.column :dc_field_id,    :integer
      t.column :dc_set_id,      :integer
    end

    create_table :dc_sets do |t|
      t.column :name,           :string
      t.column :spec,           :string
      t.column :description,    :string
    end

    add_index :oai_tokens, [:token], :uniq => true
    add_index :oai_tokens, :created_at
    add_index :oai_entries, [:oai_token_id]
    add_index :dc_fields, :updated_at
    add_index :dc_fields, :deleted
    add_index :dc_fields_dc_sets, [:dc_field_id, :dc_set_id]
  end

  def self.down
    drop_table :oai_tokens
    drop_table :dc_fields
    drop_table :dc_sets
  end
end
