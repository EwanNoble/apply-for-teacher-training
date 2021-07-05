class AddAuditTagsToAudits < ActiveRecord::Migration[6.1]
  def change
    add_column :audits, :audit_tags, :string, array: true
  end
end
