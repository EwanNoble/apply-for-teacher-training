module CandidateInterface
  class SignUpController < CandidateInterfaceController
    skip_before_action :authenticate_candidate!
    before_action :redirect_to_application_if_signed_in, except: :external_sign_up_forbidden

    def new
      @sign_up_form = CandidateInterface::SignUpForm.new
    end

    def create
      @sign_up_form = CandidateInterface::SignUpForm.new(candidate_sign_up_form_params)

      if @sign_up_form.existing_candidate?
        CandidateInterface::RequestMagicLink.for_sign_in(candidate: @sign_up_form.candidate)
        set_user_context @sign_up_form.candidate.id
        candidate = @sign_up_form.candidate
        candidate.update!(course_from_find_id: @sign_up_form.course_from_find_id)
        redirect_to candidate_interface_check_email_sign_up_path
      elsif @sign_up_form.save
        CandidateInterface::RequestMagicLink.for_sign_up(candidate: @sign_up_form.candidate)
        set_user_context @sign_up_form.candidate.id
        redirect_to candidate_interface_check_email_sign_up_path
      else
        track_validation_error(@sign_up_form)
        redirect_to candidate_interface_external_sign_up_forbidden_path and return if external_sign_up_forbidden?

        render :new
      end
    end

    def show; end

    def external_sign_up_forbidden; end

  private

    def external_sign_up_forbidden?
      @sign_up_form.errors.details[:email_address].include?(error: :dfe_signup_only)
    end

    def candidate_sign_up_form_params
      params.require(:candidate_interface_sign_up_form).permit(:email_address, :accept_ts_and_cs).merge(course_from_find_id: course_id)
    end

    def course_id
      return unless params[:providerCode]

      @provider = Provider.find_by(code: params[:providerCode])
      @course = @provider.courses.current_cycle.find_by(code: params[:courseCode]) if @provider.present?
      @course.id if @course.present?
    end
  end
end
