module Spree
  module Admin
    class ProductImportsController < BaseController

      def index
        @product_import = Spree::ProductImport.new
      end

      def show
        @product_import = Spree::ProductImport.find(params[:id])
        @products = @product_import.products
      end

      def create
        import = product_import_params.to_h
        import.merge!(created_by: spree_current_user.id)
        data_files = import.delete("data_file")
        if data_files.size > 1
          data_files.each do |data_file|
            import["data_file"] = data_file
            @product_import = Spree::ProductImport.create(import)
            ImportProductsJob.perform_later(@product_import.id, current_store.id)
          end
          redirect_to admin_product_imports_path
          return
        end
        import["data_file"] = data_files[0]
        @product_import = Spree::ProductImport.create(import)
        begin
          if @product_import.productsCount > Spree::ProductImport.settings[:num_prods_for_delayed]
            ImportProductsJob.perform_later(@product_import.id, current_store.id)
					  flash[:notice] = t('product_import_processing')
          else
            @product_import.import_data!(Spree::ProductImport.settings[:transaction])
					  flash[:success] = t('product_import_imported')
            end
        rescue StandardError => e
          @product_import.error_message=e.message+ ' ' + e.backtrace.inspect
          @product_import.failure
          if (e.is_a?(OpenURI::HTTPError))
            flash[:error] = t('product_import_http_error')
          else
            flash[:error] = "Error in controller: #{e.message} - #{e.backtrace[0]}"
          end
        end
        redirect_to admin_product_imports_path
      end

      def destroy
        @product_import = Spree::ProductImport.find(params[:id])
        if @product_import.destroy
          flash[:success] = t('delete_product_import_successful')
        end
        respond_with(@product) do |format|
          format.html { redirect_to collection_url }
          format.js  { render_js_for_destroy }
        end
      end

      private
        def product_import_params
          params.require(:product_import).permit!
        end
    end
  end
end
