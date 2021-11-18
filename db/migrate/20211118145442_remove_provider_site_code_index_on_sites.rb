class RemoveProviderSiteCodeIndexOnSites < ActiveRecord::Migration[6.1]
  def change
    remove_index :sites, name: "index_sites_on_code_and_provider_id", if_exists: true, algorithm: :concurrently
  end
end
