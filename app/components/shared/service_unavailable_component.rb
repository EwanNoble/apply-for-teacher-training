class ServiceUnavailableComponent < ViewComponent::Base
  def initialize; end

  def title_content
    HostingEnvironment.sandbox_mode? ? t('service_unavailable.sandbox_title') : t('service_unavailable.title')
  end
end
