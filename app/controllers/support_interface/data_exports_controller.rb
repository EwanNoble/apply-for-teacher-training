module SupportInterface
  class DataExportsController < SupportInterfaceController
    PAGE_SIZE = 30

    def new
      @export_types = DataExport::EXPORT_TYPES
    end

    def directory
      @export_types = DataExport::EXPORT_TYPES
    end

    def history
      @data_exports = DataExport
        .includes(:initiator)
        .order(created_at: :desc)
        .page(params[:page] || 1)
        .per(PAGE_SIZE)
    end

    def view_export_information
      @data_export = DataExport::EXPORT_TYPES[params[:data_export_type].to_sym]
    end

    def view_history
      @data_exports = DataExport.includes(:initiator).send(params[:data_export_type]).order(created_at: :desc).page(params[:page] || 1).per(PAGE_SIZE)
    end

    def create
      export_type = DataExport::EXPORT_TYPES.fetch(params.fetch(:export_type_id).to_sym)
      data_export = DataExport.create!(name: export_type.fetch(:name), initiator: current_support_user, export_type: export_type.fetch(:export_type))
      DataExporter.perform_async(export_type.fetch(:class), data_export.id, export_options)

      redirect_to support_interface_data_export_path(data_export)
    end

    def show
      @data_export = DataExport.find(params[:id])
    end

    def download
      data_export = DataExport.find(params[:id])
      data_export.update!(audit_comment: 'File downloaded')
      send_data data_export.data, filename: data_export.filename, disposition: :attachment
    end

    def data_set_documentation
      @export_type = DataExport::EXPORT_TYPES.fetch(params.fetch(:export_type_id).to_sym)
    end

  private

    def export_options
      export_definition.fetch(:export_options, {})
    end

    def export_definition
      @export_definition ||= DataExport::EXPORT_TYPES.fetch(params.fetch(:export_type_id).to_sym)
    end
  end
end
