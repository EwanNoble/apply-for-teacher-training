class BackfillSiteUuidByCodePerYear
  def initialize(recruitment_cycle_year, provider, course)
    @recruitment_cycle_year = recruitment_cycle_year
    @provider = provider
    @course = course
  end

  def call
    ActiveRecord::Base.transaction do
      sites = TeacherTrainingPublicAPI::Location.where(year: @recruitment_cycle_year, provider_code: @provider.code, course_code: @course.code).includes(:location_status).paginate(per_page: 500)
      sites.each do |site_from_api|
        binding.pry
        site_on_apply = Site.find_by(code: site_from_api.code, provider: @provider)
        split_sites_and_assign_uuids_by_year(site_from_api, site_on_apply)
      end
    end
  end

  def split_sites_and_assign_uuids_by_year(site_from_api, site_on_apply)
    if @recruitment_cycle_year == RecruitmentCycle.current_year
      site_on_apply.update(uuid: site_from_api.uuid)
    else
      duplicate_site = site_on_apply.dup.update(uuid: site_from_api.uuid)
      site_on_apply.course_options.where(recruitment_cycle_year: site_from_api.year).update(site: duplicate_site)
      duplicate_site.save!
    end
  end

end
