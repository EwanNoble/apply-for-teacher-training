module ProviderInterface
  class OffersController < ProviderInterfaceController
    before_action :set_application_choice
    before_action :confirm_application_is_in_decision_pending_state, except: %i[edit update show]
    before_action :confirm_application_is_in_offered_state, only: %i[show]
    before_action :confirm_application_can_have_offer_changed, only: %i[edit update]
    before_action :requires_make_decisions_permission, except: %i[show]

    def new
      flash[:warning] = t('.failure')
      redirect_to new_provider_interface_application_choice_decision_path(@application_choice)
    end

    def create
      @wizard = OfferWizard.new(offer_store)
      if @wizard.valid?(:save)
        MakeOffer.new(actor: current_provider_user,
                      application_choice: @application_choice,
                      course_option: @wizard.course_option,
                      update_conditions_service: update_conditions_service).save!
        @wizard.clear_state!

        flash[:success] = t('.success')
        redirect_to provider_interface_application_choice_offer_path(@application_choice)
      else
        @wizard.clear_state!
        track_validation_error(@wizard)

        flash[:warning] = t('.failure')
        redirect_to new_provider_interface_application_choice_decision_path(@application_choice)
      end
    end

    def edit
      redirect_to provider_interface_application_choice_offer_path(@application_choice)
    end

    def show
      @wizard = OfferWizard.build_from_application_choice(
        offer_store,
        @application_choice,
        provider_user_id: current_provider_user.id,
        current_step: :offer,
        decision: :change_offer,
      )
      @wizard.save_state!

      return unless provider_user_can_make_decisions

      @providers = available_providers
      @courses = available_courses(@application_choice.current_course.provider.id)
      @course_options = available_course_options(@application_choice.current_course.id, @application_choice.current_course_option.study_mode)
    end

    def update
      @wizard = OfferWizard.new(offer_store)
      if @wizard.valid?(:save)
        begin
          ChangeOffer.new(actor: current_provider_user,
                          application_choice: @application_choice,
                          course_option: @wizard.course_option,
                          update_conditions_service: update_conditions_service).save!
          @wizard.clear_state!
          flash[:success] = t('.success')
        rescue IdenticalOfferError
          @wizard.clear_state!
          flash[:success] = t('.success')
        end
      else
        @wizard.clear_state!
        track_validation_error(@wizard)

        flash[:warning] = t('.failure')
      end
      redirect_to provider_interface_application_choice_offer_path(@application_choice)
    end

  private

    def offer_store
      key = "offer_wizard_store_#{current_provider_user.id}_#{@application_choice.id}"
      WizardStateStores::RedisStore.new(key: key)
    end

    def confirm_application_is_in_decision_pending_state
      return if @application_choice.decision_pending?

      redirect_to(provider_interface_application_choice_path(@application_choice))
    end

    def confirm_application_is_in_offered_state
      return if ApplicationStateChange::OFFERED_STATES.include?(@application_choice.status.to_sym)

      redirect_to(provider_interface_application_choice_path(@application_choice))
    end

    def confirm_application_can_have_offer_changed
      return if @application_choice.offer?

      redirect_to(provider_interface_application_choice_path(@application_choice))
    end

    def action
      'back' if !!params[:back]
    end

    def available_providers
      query_service.available_providers
    end

    def available_courses(provider_id)
      query_service.available_courses(provider: Provider.find(provider_id))
    end

    def available_course_options(course_id, study_mode)
      query_service.available_course_options(course: Course.find(course_id), study_mode: study_mode)
    end

    def query_service
      @query_service ||= GetChangeOfferOptions.new(
        user: current_provider_user,
        current_course: @application_choice.current_course,
      )
    end

    def update_conditions_service
      SaveOfferConditionsFromParams.new(
        application_choice: @application_choice,
        standard_conditions: @wizard.standard_conditions,
        further_condition_attrs: @wizard.further_condition_attrs,
      )
    end

    helper_method :provider_user_can_make_decisions

    def provider_user_can_make_decisions
      @provider_can_make_decisions = current_provider_user.authorisation.can_make_decisions?(
        application_choice: @application_choice,
        course_option_id: @application_choice.current_course_option.id,
      )
    end
  end
end
