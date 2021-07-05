module AuditedTagging
  extend ActiveSupport::Concern

  included do
    attr_accessor :audit_tags

    set_callback :audit, :around, lambda { |_form, block|
      audit = block.call
      audit.audit_tags = audit_tags
      audit.save
    }
  end
end
