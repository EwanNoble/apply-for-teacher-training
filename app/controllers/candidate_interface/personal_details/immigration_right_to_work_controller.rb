module CandidateInterface
  module PersonalDetails
    class ImmigrationRightToWorkController < CandidateInterfaceController
      before_action :redirect_to_dashboard_if_submitted

      def new
        @form = ImmigrationRightToWorkForm.build_from_application(current_application)
      end

      def create
        @form = ImmigrationRightToWorkForm.new(right_to_work_params)

        if @form.save(current_application)
          if @form.right_to_work_or_study?
            redirect_to candidate_interface_immigration_status_path
          else
            redirect_to candidate_interface_immigration_route_path
          end
        else
          track_validation_error(@form)
          render :new
        end
      end

    private

      def right_to_work_params
        {
          immigration_right_to_work: params.dig(
            :candidate_interface_immigration_right_to_work_form,
            :immigration_right_to_work,
          ),
        }
      end
    end
  end
end
