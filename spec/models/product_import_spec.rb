require 'spec_helper'

module Spree
  describe ProductImport do
    describe "#create_variant_for" do
      before do
        product; size; color; option_color; option_size
      end

      # let(:product) { FactoryGirl.create(:product, :sku => "001", :permalink => "S0388G-bloch-kids-tap-flexewe") } # UndefinedMethod: permalink=
      let(:product) { FactoryGirl.create(:product, sku: '001') }
      let(:size) { FactoryGirl.create(:option_type, name: 'tshirt-size') }
      let(:color) { FactoryGirl.create(:option_type, name: 'tshirt-color', presentation: 'Color') }
      let(:option_color) { FactoryGirl.create(:option_value, name: 'blue', presentation: 'Blue', option_type: color) }
      let(:option_size) { FactoryGirl.create(:option_value, :name => "s", :presentation => "Small", :option_type => size) }

      let(:params) do
        { sku: "002", name: "S0388G Bloch Kids Tap Flexww", description: "Lace Up Split Sole Leather Tap Shoe",
          cost_price: "29.25", price: "54.46", available_on: "1/1/10", :"tshirt-color"=>"Blue", :"tshirt-size"=>"Small",
          on_hand: "2", height: "3", width: "4", depth: "9", weight: "1", position: "0", category: "Categories > Clothing", permalink: "S0388G-bloch-kids-tap-flexewe"
        }
      end

      it "creates a new variant when product already exist" do
        expect do
          ProductImport.new.send(:create_variant_for, product, with: params)
        end.to change(product.variants, :count).by(1)

        variant = product.variants.last

        expect(variant.price.to_f).to eq 54.46
        expect(variant.cost_price.to_f).to eq 29.25
        expect(product.option_types =~ [size, color])
        expect(variant.option_values =~ [option_size, option_color])
      end

      it "creates missing option_values for new variant" do
        ProductImport.new.send(:create_variant_for, product, with: params.merge(:"tshirt-size" => "Large", :"tshirt-color" => "Yellow"))
        variant = product.variants.last
        expect(product.option_types =~ [size, color])
        expect(variant.option_values =~ OptionValue.where(name: %w(Large Yellow)))
      end

      it "duplicates option_values for existing variant" do
        expect do
          ProductImport.new.send(:create_variant_for, product, with: params.merge(:"tshirt-size" => "Large", :"tshirt-color" => "Yellow"))
          ProductImport.new.send(:create_variant_for, product, with: params.merge(:"tshirt-size" => "Large", :"tshirt-color" => "Yellow"))
        end.to change(product.variants, :count).by(1)
        variant = product.variants.last
        expect(product.option_types =~ [size, color])
        expect(variant.option_values.reload =~ OptionValue.where(name: %w(Large Yellow)))
      end

      it "throws an exception when variant with sku exist for another product" do
        other_product = FactoryGirl.create(:product, sku: "002")
        expect do
          ProductImport.new.send(:create_variant_for, product, with: params.merge(:"tshirt-size" => "Large", :"tshirt-color" => "Yellow"))
        end.to raise_error(SkuError)
      end
    end

    describe "#import_data!" do
      let(:valid_import) { ProductImport.create data_file: File.new(File.join(File.dirname(__FILE__), '..', 'fixtures', 'valid.csv')) }
      let(:invalid_import) { ProductImport.create data_file: File.new(File.join(File.dirname(__FILE__), '..', 'fixtures', 'invalid.csv')) }

      context "on valid csv" do
        it "create products successfully" do
          expect { valid_import.import_data! }.to change(Product, :count).by(3)
          # Product.last.variants.count.should == 2
        end

        it "tracks product created ids" do
          valid_import.import_data!
          valid_import.reload

          spree_ids = Spree::Product.all.map(&:id)
          valid_import.product_ids.each do |import_id|
            expect(spree_ids.include?(import_id))
          end
        end

        it "handles product properties" do
          Property.create name: "brand", presentation: "Brand"

          expect { @import = ProductImport.create(data_file: File.new(File.join(File.dirname(__FILE__), '..', 'fixtures', 'products_with_properties.csv'))).import_data!(true) }.to change(Product, :count).by(3)

          product = Product.last
          expect(product.product_properties.map(&:value)).to eq(['Rails'])
          # Commented out because this is a properties test, not a variant one.
          # expect(product.variants.count).to eq 2
        end

        it "sets state to completed" do
          valid_import.import_data!
          expect(valid_import.reload.state).to eq "completed"
        end
      end

      context "on invalid csv" do
        it "doesn't track product's created ids" do
          expect { invalid_import.import_data! }.to raise_error(ImportError)
          invalid_import.reload
          expect(invalid_import.product_ids).to be_empty
          expect(invalid_import.products).to be_empty
        end

        context "when params = true (transaction)" do
          it "rollback transation" do
            expect { invalid_import.import_data! }.to raise_error(ImportError)
            expect(Product.count).to eq 0
          end

          it "sets state to failed" do
            expect { invalid_import.import_data! }.to raise_error(ImportError)
            expect(invalid_import.state).to eq "failed"
          end
        end

        context "when params = false (no transaction)", focus: true do
          it "sql are permanent" do
            expect { invalid_import.import_data!(false) }.to raise_error(ImportError)
            # How many invalid products are there in the fixture?
            # 
            expect(Product.count).to eq 1
          end

          it "sets state to failed" do
            expect { invalid_import.import_data!(false) }.to raise_error(ImportError)
            expect(invalid_import.reload.state).to eq "failed"
          end
        end
      end
    end

    describe "#destroy_products" do
      it "destroys associations" do
        expect do
          (@import = ProductImport.create(
            data_file: File.new(File.join(File.dirname(__FILE__), '..', 'fixtures', 'products_with_properties.csv'))))
            .import_data!(true)
        end.to change(Product, :count).by(3)
        @import.destroy
        expect(Variant.count).to eq 0
      end
    end
  end
end
