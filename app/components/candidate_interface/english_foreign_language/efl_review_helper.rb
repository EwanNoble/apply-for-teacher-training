module CandidateInterface
  module EnglishForeignLanguage
    module EflReviewHelper
      def do_you_have_a_qualification_row(value:, return_to_application_review: false)
        {
          key: 'Have you done an English as a foreign language assessment?',
          value: value,
          action: {
            href: candidate_interface_english_foreign_language_edit_start_path(return_to_params(return_to_application_review)),
            visually_hidden_text: 'whether or not you have a qualification',
          },
          html_attributes: {
            data: {
              qa: 'english-as-a-foreign-language',
            },
          },
        }
      end

      def type_of_qualification_row(name:, return_to_application_review: false)
        {
          key: 'Type of assessment',
          value: name,
          action: {
            href: candidate_interface_english_foreign_language_type_path(return_to_params(return_to_application_review)),
            visually_hidden_text: 'type of assessment',
          },
          html_attributes: {
            data: {
              qa: 'english-as-a-foreign-language-type',
            },
          },
        }
      end

      def return_to_params(return_to_application_review)
        { 'return-to' => 'application-review' } if return_to_application_review
      end
    end
  end
end
