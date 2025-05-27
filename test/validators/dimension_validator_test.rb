# frozen_string_literal: true

require "test_helper"
require "validators/shared_examples/checks_validator_validity"
require "validators/shared_examples/is_performance_optimized"
require "validators/shared_examples/works_fine_with_attachables"
require "validators/shared_examples/works_with_all_rails_common_validation_options"

describe ActiveStorageValidations::DimensionValidator do
  include ValidatorHelpers

  let(:validator_test_class) { Dimension::Validator }
  let(:params) { {} }

  describe "#check_validity!" do
    include ChecksValidatorValidity

    describe "#ensure_dimension_in_option_validity" do
      describe "when the passed option is a Range" do
        subject { validator_test_class::CheckValidityDimensionInRange.new(params) }

        it "does not perform a check, and therefore is valid" do
          assert_nothing_raised { subject }
        end
      end

      describe "when the passed option is a Proc" do
        subject { validator_test_class::CheckValidityDimensionInProc.new(params) }

        it "does not perform a check, and therefore is valid" do
          assert_nothing_raised { subject }
        end
      end

      describe "when the passed option is neither a Range nor a Proc" do
        subject { validator_test_class::CheckValidityInvalidDimensionIn.new(params) }

        let(:error_message) { "{ width: { in: value } } value must be a Range (min..max)" }

        it "raises an error at model initialization" do
          assert_raises(ArgumentError, error_message) { subject }
        end
      end
    end

    describe "#ensure_min_max_option_validity" do
      %i[min max].each do |bound|
        describe "when the passed option is a Range" do
          subject { "#{validator_test_class}::CheckValidity#{bound.to_s.capitalize}Range".constantize.new(params) }

          it "does not perform a check, and therefore is valid" do
            assert_nothing_raised { subject }
          end
        end

        describe "when the passed option is a Proc" do
          subject { "#{validator_test_class}::CheckValidity#{bound.to_s.capitalize}Proc".constantize.new(params) }

          it "does not perform a check, and therefore is valid" do
            assert_nothing_raised { subject }
          end
        end

        describe "when the passed option is neither a Range nor a Proc" do
          subject { "#{validator_test_class}::CheckValidityInvalid#{bound.to_s.capitalize}".constantize.new(params) }

          let(:error_message) { "{ #{bound}: value } value must be a Range (#{bound}_width..#{bound}_height)" }

          it "raises an error at model initialization" do
            assert_raises(ArgumentError, error_message) { subject }
          end
        end
      end
    end
  end

  describe "Validator checks" do
    include WorksFineWithAttachables

    let(:model) { validator_test_class::Check.new(params) }

    %w[width height].each do |dimension|
      describe ":#{dimension} option" do
        %w[value proc].each do |value_type|
          describe value_type do
            describe ":#{dimension} (e.g { #{dimension}: 500 })" do
              # validates :width, dimension: { width: 500 }
              # validates :width_proc, dimension: { width: -> (record) { 500 } }
              # validates :height, dimension: { height: 500 }
              # validates :height_proc, dimension: { height: -> (record) { 500 } }
              let(:attribute) { :"#{dimension}#{'_proc' if value_type == 'proc'}" }

              describe "when provided with a lower #{dimension} than the #{dimension} specified in the model validations" do
                subject { model.public_send(attribute).attach(image_150x150_file) and model }

                let(:error_options) do
                  {
                    length: 500,
                    "#{dimension}": value_type == "value" ? 500 : ->(record) { 500 },
                    filename: "image_150x150_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_equal_to", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end

              describe "when provided with the same #{dimension} value as specified in the model validations" do
                subject { model.public_send(attribute).attach(image_500x500_file) and model }

                it { is_expected_to_be_valid }
              end

              describe "when provided with a higher #{dimension} than the #{dimension} specified in the model validations" do
                subject { model.public_send(attribute).attach(image_600x800_file) and model }

                let(:error_options) do
                  {
                    length: 500,
                    "#{dimension}": value_type == "value" ? 500 : ->(record) { 500 },
                    filename: "image_600x800_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_equal_to", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end
            end

            describe "#{dimension}: :min (e.g { #{dimension}: { min: 500 } })" do
              # validates :width_min, dimension: { width: { min: 500 } }
              # validates :width_min_proc, dimension: { width: { min: -> (record) { 500 } } }
              # validates :height_min, dimension: { height: { min: 500 } }
              # validates :height_min_proc, dimension: { height: { min: -> (record) { 500 } } }
              let(:attribute) { :"#{dimension}_min#{'_proc' if value_type == 'proc'}" }

              describe "when provided with a lower #{dimension} than the min #{dimension} specified in the model validations" do
                subject { model.public_send(attribute).attach(image_150x150_file) and model }

                let(:error_options) do
                  {
                    length: 500,
                    "#{dimension}": { min: value_type == "value" ? 500 : ->(record) { 500 } },
                    filename: "image_150x150_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_greater_than_or_equal_to", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end

              describe "when provided with the same #{dimension} value as specified as min in the model validations" do
                subject { model.public_send(attribute).attach(image_500x500_file) and model }

                it { is_expected_to_be_valid }
              end

              describe "when provided with a higher #{dimension} than the #{dimension} specified in the model validations" do
                subject { model.public_send(attribute).attach(image_600x800_file) and model }

                it { is_expected_to_be_valid }
              end
            end

            describe "#{dimension}: :max (e.g { #{dimension}: { max: 500 } })" do
              # validates :width_max, dimension: { width: { max: 500 } }
              # validates :width_max_proc, dimension: { width: { max: -> (record) { 500 } } }
              # validates :height_max, dimension: { height: { max: 500 } }
              # validates :height_max_proc, dimension: { height: { max: -> (record) { 500 } } }
              let(:attribute) { :"#{dimension}_max#{'_proc' if value_type == 'proc'}" }

              describe "when provided with a lower #{dimension} than the max #{dimension} specified in the model validations" do
                subject { model.public_send(attribute).attach(image_150x150_file) and model }

                it { is_expected_to_be_valid }
              end

              describe "when provided with the same #{dimension} value as specified as max in the model validations" do
                subject { model.public_send(attribute).attach(image_500x500_file) and model }

                it { is_expected_to_be_valid }
              end

              describe "when provided with a higher #{dimension} than the #{dimension} specified in the model validations" do
                subject { model.public_send(attribute).attach(image_600x800_file) and model }

                let(:error_options) do
                  {
                    length: 500,
                    "#{dimension}": { max: value_type == "value" ? 500 : ->(record) { 500 } },
                    filename: "image_600x800_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_less_than_or_equal_to", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end
            end

            describe "#{dimension}: :min and :max (e.g { #{dimension}: { min: 400, max: 600 } })" do
              # validates :width_min_max, dimension: { width: { min: 400, max: 600 } }
              # validates :width_min_max_proc, dimension: { width: { min: -> (record) { 400 }, max: -> (record) { 600 } } }
              # validates :height_min_max, dimension: { height: { min: 400, max: 600 } }
              # validates :height_min_max_proc, dimension: { height: { min: -> (record) { 400 }, max: -> (record) { 600 } } }
              let(:attribute) { :"#{dimension}_min_max#{'_proc' if value_type == 'proc'}" }

              describe "when provided with a lower #{dimension} than the min #{dimension} specified in the model validations" do
                subject { model.public_send(attribute).attach(image_150x150_file) and model }

                let(:error_options) do
                  {
                    length: 400,
                    "#{dimension}": { min: value_type == "value" ? 400 : ->(record) { 400 }, max: value_type == "value" ? 600 : ->(record) { 600 } },
                    filename: "image_150x150_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_greater_than_or_equal_to", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end

              describe "when provided with a #{dimension} value as included in the min and max #{dimension} specified in the model validations" do
                subject { model.public_send(attribute).attach(image_500x500_file) and model }

                it { is_expected_to_be_valid }
              end

              describe "when provided with a higher #{dimension} than the max #{dimension} specified in the model validations" do
                subject { model.public_send(attribute).attach(image_1200x900_file) and model }

                let(:error_options) do
                  {
                    length: 600,
                    "#{dimension}": { min: value_type == "value" ? 400 : ->(record) { 400 }, max: value_type == "value" ? 600 : ->(record) { 600 } },
                    filename: "image_1200x900_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_less_than_or_equal_to", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end
            end

            describe "#{dimension}: :in (e.g { #{dimension}: { in: 400..600 } })" do
              # validates :width_in, dimension: { width: { in: 400..600 } }
              # validates :width_in_proc, dimension: { width: { in: -> (record) { 400..600 } } }
              # validates :height_in, dimension: { height: { in: 400..600 } }
              # validates :height_in_proc, dimension: { height: { in: -> (record) { 400..600 } } }
              let(:attribute) { :"#{dimension}_in#{'_proc' if value_type == 'proc'}" }

              describe "when provided with a lower #{dimension} than the min #{dimension} specified in the model validations" do
                subject { model.public_send(attribute).attach(image_150x150_file) and model }

                let(:error_options) do
                  {
                    "#{dimension}": { in: value_type == "value" ? 400..600 : ->(record) { 400..600 } },
                    min: 400,
                    max: 600,
                    filename: "image_150x150_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_included_in", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end

              describe "when provided with a #{dimension} value as included in the min and max #{dimension} specified in the model validations" do
                subject { model.public_send(attribute).attach(image_500x500_file) and model }

                it { is_expected_to_be_valid }
              end

              describe "when provided with a higher #{dimension} than the max #{dimension} specified in the model validations" do
                subject { model.public_send(attribute).attach(image_1200x900_file) and model }

                let(:error_options) do
                  {
                    "#{dimension}": { in: value_type == "value" ? 400..600 : ->(record) { 400..600 } },
                    min: 400,
                    max: 600,
                    filename: "image_1200x900_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_included_in", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end
            end
          end
        end
      end
    end

    describe ":min option" do
      %w[value proc].each do |value_type|
        describe value_type do
          describe ":min (e.g { min: 500..500 })" do
            # validates :min, dimension: { min: 500..500   }
            # validates :min_proc, dimension: { min: -> (record) { 500..500 } }
            let(:attribute) { :"min#{'_proc' if value_type == 'proc'}" }

            describe "when provided with a lower width or height than the min specified in the model validations" do
              subject { model.public_send(attribute).attach(image_150x150_file) and model }

              let(:error_options) do
                {
                  width: 500,
                  height: 500,
                  filename: "image_150x150_file.png"
                }
              end

              it { is_expected_not_to_be_valid }
              it { is_expected_to_include_error_message("dimension_min_not_included_in", error_options: error_options) }
              it { is_expected_to_have_error_options(error_options) }
            end

            describe "when provided with the same width or height value as specified in the model validations" do
              subject { model.public_send(attribute).attach(image_500x500_file) and model }

              it { is_expected_to_be_valid }
            end

            describe "when provided with a higher width or height than the min specified in the model validations" do
              subject { model.public_send(attribute).attach(image_600x800_file) and model }

              it { is_expected_to_be_valid }
            end
          end
        end
      end
    end

    describe ":max option" do
      %w[value proc].each do |value_type|
        describe value_type do
          describe ":max (e.g { max: 500..500 })" do
            # validates :max, dimension: { max: 500..500   }
            # validates :max_proc, dimension: { max: -> (record) { 500..500 } }
            let(:attribute) { :"max#{'_proc' if value_type == 'proc'}" }

            describe "when provided with a lower width or height than the max specified in the model validations" do
              subject { model.public_send(attribute).attach(image_150x150_file) and model }

              it { is_expected_to_be_valid }
            end

            describe "when provided with the same width or height value as specified in the model validations" do
              subject { model.public_send(attribute).attach(image_500x500_file) and model }

              it { is_expected_to_be_valid }
            end

            describe "when provided with a higher width or height than the max specified in the model validations" do
              subject { model.public_send(attribute).attach(image_600x800_file) and model }

              let(:error_options) do
                {
                  width: 500,
                  height: 500,
                  filename: "image_600x800_file.png"
                }
              end

              it { is_expected_not_to_be_valid }
              it { is_expected_to_include_error_message("dimension_max_not_included_in", error_options: error_options) }
              it { is_expected_to_have_error_options(error_options) }
            end
          end
        end
      end
    end

    describe "Integration tests" do
      describe ":width exact + :height exact" do
        let(:attribute) { :width_height_exact }

        describe "when provided with an image that has the same width and height as specified in the model validations" do
          subject { model.public_send(attribute).attach(image_600x600_file) and model }

          it { is_expected_to_be_valid }
        end

        describe "when provided with an image that has a different width than specified in the model validations" do
          subject { model.public_send(attribute).attach(image_800x600_file) and model }

          let(:error_options) do
            {
              width: 600,
              height: 600,
              length: 600,
              filename: "image_800x600_file.png"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_width_not_equal_to", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end

        describe "when provided with an image that has a different height than specified in the model validations" do
          subject { model.public_send(attribute).attach(image_600x800_file) and model }

          let(:error_options) do
            {
              width: 600,
              height: 600,
              length: 600,
              filename: "image_600x800_file.png"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_height_not_equal_to", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end

        describe "when provided with an image that has a different height and a different width than specified in the model validations" do
          subject { model.public_send(attribute).attach(image_1200x900_file) and model }

          let(:error_options) do
            {
              width: 600,
              height: 600,
              length: 600,
              filename: "image_1200x900_file.png"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_width_not_equal_to", error_options: error_options) }
          it { is_expected_to_include_error_message("dimension_height_not_equal_to", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end
      end

      describe ":width in + :height in" do
        let(:attribute) { :width_height_in }

        describe "when provided with an image that has a valid width and height as specified in the model validations" do
          subject { model.public_send(attribute).attach(image_600x600_file) and model }

          it { is_expected_to_be_valid }
        end

        describe "when provided with an image that has lower width than the min specified in the model validations" do
          subject { model.public_send(attribute).attach(image_500x700_file) and model }

          let(:error_options) do
            {
              width: { in: 550..750 },
              height: { in: 550..750 },
              min: 550,
              max: 750,
              filename: "image_500x700_file.png"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_width_not_included_in", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end

        describe "when provided with an image that has lower height than the min specified in the model validations" do
          subject { model.public_send(attribute).attach(image_700x500_file) and model }

          let(:error_options) do
            {
              width: { in: 550..750 },
              height: { in: 550..750 },
              min: 550,
              max: 750,
              filename: "image_700x500_file.png"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_height_not_included_in", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end

        describe "when provided with an image that has lower width and height than the mins specified in the model validations" do
          subject { model.public_send(attribute).attach(image_500x500_file) and model }

          let(:error_options) do
            {
              width: { in: 550..750 },
              height: { in: 550..750 },
              min: 550,
              max: 750,
              filename: "image_500x500_file.png"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_width_not_included_in", error_options: error_options) }
          it { is_expected_to_include_error_message("dimension_height_not_included_in", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end
      end
    end

    describe "Edge cases" do
      describe "when the passed file is not a valid media" do
        subject { model.public_send(attribute).attach(empty_io_file) and model }

        let(:attribute) { :with_invalid_media_file }
        let(:error_options) do
          {
            filename: empty_io_file[:filename]
          }
        end

        it { is_expected_not_to_be_valid }
        it { is_expected_to_include_error_message("media_metadata_missing", error_options: error_options) }
        it { is_expected_to_have_error_options(error_options) }
      end

      describe "when the passed file is a pdf" do
        describe "valid pdf" do
          subject { model.public_send(attribute).attach(pdf_150x150_file) and model }

          let(:attribute) { :with_pdf_file }
          let(:error_options) do
            {
              filename: pdf_150x150_file[:filename]
            }
          end

          it { is_expected_to_be_valid }
        end

        describe "invalid pdf" do
          subject { model.public_send(attribute).attach(pdf_200x300_file) and model }

          let(:attribute) { :with_pdf_file }
          let(:error_options) do
            {
              length: 150,
              width: 150,
              height: 150,
              filename: "pdf_200x300_file.pdf"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_width_not_equal_to", error_options: error_options) }
          it { is_expected_to_include_error_message("dimension_height_not_equal_to", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end
      end
    end
  end

  describe "Blob Metadata" do
    let(:attachable) do
      {
        io: File.open(Rails.root.join("public", "image_150x150.png")),
        filename: "image_150x150.png",
        content_type: "image/png"
      }
    end

    include IsPerformanceOptimized
  end

  describe "Rails options" do
    include WorksWithAllRailsCommonValidationOptions
  end
end
