module APIDocs
  module VendorAPIDocs
    class ReferenceController < APIDocsController
      def reference
        @api_reference = APIReference.new(VendorAPISpecification.new.as_hash, version: '1.0')
      end

      def draft
        return redirect_to api_docs_reference_path unless FeatureFlag.active?(:draft_vendor_api_specification)

        @api_reference = APIReference.new(VendorAPISpecification.new(version: '1.1').as_hash, version: '1.1')
      end
    end
  end
end
