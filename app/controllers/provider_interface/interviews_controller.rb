module ProviderInterface
  class InterviewsController < ProviderInterfaceController
    include ClearWizardCache

    before_action :set_application_choice
    before_action :requires_set_up_interviews_permission, except: %i[index]
    before_action :confirm_application_is_in_decision_pending_state, except: %i[index]
    before_action :redirect_to_index_if_store_cleared, only: %i[create]
    before_action :redirect_to_index_if_edit_store_cleared, only: %i[update]
    before_action :redirect_to_index_if_cancel_store_cleared, only: %i[destroy]

    def index
      application_at_interviewable_stage = ApplicationStateChange::INTERVIEWABLE_STATES.include?(
        @application_choice.status.to_sym,
      )
      @provider_can_make_decisions =
        current_provider_user.authorisation.can_make_decisions?(application_choice: @application_choice,
                                                                course_option: @application_choice.current_course_option)
      provider_can_set_up_interviews =
        current_provider_user.authorisation.can_set_up_interviews?(application_choice: @application_choice,
                                                                   course_option: @application_choice.current_course_option)
      @interviews_can_be_created_and_edited = application_at_interviewable_stage && provider_can_set_up_interviews

      redirect_to provider_interface_application_choice_path if @application_choice.interviews.none?
    end

    def new
      clear_wizard_if_new_entry(InterviewWizard.new(interview_store, {}))

      @wizard = InterviewWizard.new(interview_store, interview_form_context_params.merge(current_step: 'input', action: action))
      @wizard.referer ||= request.referer
      @wizard.save_state!
    end

    def edit
      clear_wizard_if_new_entry(InterviewWizard.new(edit_interview_store(interview_id), {}))

      @interview = @application_choice.interviews.find(interview_id)

      @wizard = InterviewWizard.from_model(edit_interview_store(interview_id), @interview, 'edit', action)
      @wizard.referer ||= request.referer
      @wizard.save_state!
    end

    def create
      @wizard = InterviewWizard.new(interview_store, interview_form_context_params)

      if @wizard.valid?
        CreateInterview.new(
          actor: current_provider_user,
          application_choice: @application_choice,
          provider: @wizard.provider,
          date_and_time: @wizard.date_and_time,
          location: @wizard.location,
          additional_details: @wizard.additional_details,
        ).save!

        @wizard.clear_state!

        flash[:success] = t('.success')
        redirect_to provider_interface_application_choice_interviews_path(@application_choice)
      else
        track_validation_error(@wizard)
        render :new
      end
    end

    def update
      @interview = @application_choice.interviews.find(interview_id)
      @wizard = InterviewWizard.new(edit_interview_store(interview_id), interview_form_context_params)

      if @wizard.valid?
        UpdateInterview.new(
          actor: current_provider_user,
          interview: @interview,
          provider: @wizard.provider,
          date_and_time: @wizard.date_and_time,
          location: @wizard.location,
          additional_details: @wizard.additional_details,
        ).save!

        @wizard.clear_state!

        flash[:success] = t('.success')
        redirect_to provider_interface_application_choice_interviews_path(@application_choice)
      else
        track_validation_error(@wizard)
        render :edit
      end
    end

    def destroy
      @interview = @application_choice.interviews.find(interview_id)
      @wizard = CancelInterviewWizard.new(cancel_interview_store(interview_id))

      CancelInterview.new(
        actor: current_provider_user,
        application_choice: @application_choice,
        interview: @interview,
        cancellation_reason: @wizard.cancellation_reason,
      ).save!

      @wizard.clear_state!

      flash[:success] = t('.success')
      redirect_to provider_interface_application_choice_path(@application_choice)
    end

  private

    def interview_form_context_params
      {
        application_choice: @application_choice,
        provider_user: current_provider_user,
      }
    end

    def interview_params
      params
        .require(:provider_interface_interview_wizard)
        .permit(:date, :time, :location, :additional_details, :provider_id)
        .transform_values(&:strip)
        .merge(interview_form_context_params)
    end

    def interview_store
      key = "interview_wizard_store_#{current_provider_user.id}_#{@application_choice.id}"
      WizardStateStores::RedisStore.new(key: key)
    end

    def edit_interview_store(interview_id)
      key = "interview_wizard_store_#{current_provider_user.id}_#{@application_choice.id}_#{interview_id}"
      WizardStateStores::RedisStore.new(key: key)
    end

    def cancel_interview_store(interview_id)
      key = "cancel_interview_wizard_store_#{current_provider_user.id}_#{@application_choice.id}_#{interview_id}"
      WizardStateStores::RedisStore.new(key: key)
    end

    def confirm_application_is_in_decision_pending_state
      return if @application_choice.decision_pending?

      redirect_back(fallback_location: provider_interface_application_choice_path(@application_choice))
    end

    def redirect_to_index_if_store_cleared
      redirect_to provider_interface_application_choice_interviews_path(@application_choice) if interview_store.read.blank?
    end

    def redirect_to_index_if_edit_store_cleared
      return if edit_interview_store(interview_id).read.present?

      redirect_to provider_interface_application_choice_interviews_path(@application_choice)
    end

    def redirect_to_index_if_cancel_store_cleared
      return if cancel_interview_store(interview_id).read.present?

      redirect_to provider_interface_application_choice_interviews_path(@application_choice)
    end

    def interview_id
      params.permit(:id)[:id]
    end

    def action
      'back' if !!params[:back]
    end

    def wizard_controller_excluded_paths
      [provider_interface_application_choice_interviews_path]
    end

    def wizard_flow_controllers
      ['provider_interface/interviews', 'provider_interface/interviews/checks'].freeze
    end
  end
end
