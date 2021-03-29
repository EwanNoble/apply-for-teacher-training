require 'rails_helper'

RSpec.describe DataMigrations::BackfillExportType do
  it 'backfills the export_type column in Data Exports' do
    data_export = create(:data_export, export_type: nil)

    described_class.new.change
    expect(data_export.reload.export_type).to eq 'active_provider_user_permissions'
  end
end