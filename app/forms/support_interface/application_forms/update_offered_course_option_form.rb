module SupportInterface
  module ApplicationForms
    class UpdateOfferedCourseOptionForm
      include ActiveModel::Model

      attr_accessor :course_option_id, :audit_comment, :accept_guidance

      validates :course_option_id, :audit_comment, :accept_guidance, presence: true
      validates_with ZendeskUrlValidator

      def save(application_choice)
        self.accept_guidance = ActiveModel::Type::Boolean.new.cast(accept_guidance)

        return false unless valid?

        application_choice.update_course_option_and_associated_fields!(course_option, audit_comment: audit_comment)
      end

      def course_option
        @_course_option ||= CourseOption.find(course_option_id)
      end
    end
  end
end
