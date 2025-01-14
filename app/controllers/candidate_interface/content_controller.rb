module CandidateInterface
  class ContentController < CandidateInterfaceController
    include ContentHelper
    skip_before_action :authenticate_candidate!
    skip_before_action :set_user_context

    def accessibility
      render_content_page :accessibility
    end

    def privacy_policy
      render_content_page :service_privacy_notice
    end

    def cookies_page
      @application = :apply
      @cookie_ga_code = ENV.fetch('GOOGLE_ANALYTICS_APPLY', '').gsub(/-/, '_')
      @cookie_preferences = CookiePreferencesForm.new(consent: cookies['consented-to-apply-cookies'])
      @cookie_settings_path = candidate_interface_cookie_preferences_path
      session[:previous_referer] = request.referer

      render 'content/cookies'
    end

    def terms_candidate
      render_content_page :terms_candidate
    end

    def complaints
      render 'content/complaints'
    end

    def providers; end
  end
end
