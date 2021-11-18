module DataMigrations
  class RemoveProviderAndCodeIndexFromSites
    TIMESTAMP = 20211118133754
    MANUAL_RUN = false

    def change
      remove_index :sites, name: :index_sites_on_code_and_provider_id
    end
  end
end
