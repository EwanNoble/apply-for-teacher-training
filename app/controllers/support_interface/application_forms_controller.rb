module SupportInterface
  class ApplicationFormsController < SupportInterfaceController
    def index
      @filter = SupportInterface::ApplicationsFilter.new(params: params)
      @application_forms = @filter.filter_records(ApplicationForm)
    end

    def show
      @application_form = application_form
    end

    def unavailable_choices
      @monitor = SupportInterface::ApplicationMonitor.new
    end

    def audit
      @application_form = application_form
    end

  private

    def application_form
      @_application_form ||= ApplicationForm.find(params[:application_form_id])
    end
  end
end
