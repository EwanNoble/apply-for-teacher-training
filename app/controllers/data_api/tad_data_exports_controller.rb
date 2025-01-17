module DataAPI
  class TADDataExportsController < ActionController::API
    include ServiceAPIUserAuthentication
    include RemoveBrowserOnlyHeaders

    # Makes PG::QueryCanceled statement timeout errors appear in Skylight
    # against the controller action that triggered them
    # instead of bundling them with every other ErrorsController#internal_server_error
    rescue_from ActiveRecord::QueryCanceled, with: :statement_timeout

    def index
      exports = DataAPI::TADExport.all

      formatted_exports = exports.map do |export|
        {
          export_date: export.completed_at,
          description: export.name,
          url: data_api_tad_export_url(export.id),
        }
      end

      render json: { data: formatted_exports.as_json }
    end

    def show
      data_export = DataAPI::TADExport.all.find(params[:id])
      serve_export(data_export)
    end

    def latest
      data_export = DataAPI::TADExport.latest
      serve_export(data_export)
    end

    def candidates
      all = DataExport
        .where(export_type: :ministerial_report_candidates_export)
        .where.not(completed_at: nil)

      data_export = all.last

      serve_export(data_export)
    end

    def applications
      all = DataExport
        .where(export_type: :ministerial_report_applications_export)
        .where.not(completed_at: nil)

      data_export = all.last

      serve_export(data_export)
    end

    def subject_domicile_nationality_latest
      data_export = DataExport
        .where(export_type: :tad_subject_domicile_nationality)
        .where.not(completed_at: nil)
        .last

      serve_export(data_export)
    end

    def applications_by_subject_route_and_degree_grade
      all = DataExport
      .where(export_type: :applications_by_subject_route_and_degree_grade)
      .where.not(completed_at: nil)

      data_export = all.last

      serve_export(data_export)
    end

    def applications_by_demographic_domicile_and_degree_class
      all = DataExport
        .where(export_type: :applications_by_demographic_domicile_and_degree_class)
        .where.not(completed_at: nil)

      data_export = all.last

      serve_export(data_export)
    end

  private

    def serve_export(export)
      export.update!(audit_comment: "File downloaded via API using token ID #{@authenticating_token.id}")
      send_data export.data, filename: export.filename
    end

    def statement_timeout
      render json: {
        errors: [
          {
            error: 'InternalServerError',
            message: 'The server encountered an unexpected condition that prevented it from fulfilling the request',
          },
        ],
      }, status: :internal_server_error
    end
  end
end
