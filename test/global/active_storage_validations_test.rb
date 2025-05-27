# frozen_string_literal: true

require "test_helper"

describe ActiveStorageValidations do
  let(:instance) { ActiveStorageValidations::Check.new }

  it "is part of the app's modules" do
    _(ActiveStorageValidations).must_be_kind_of Module
  end

  describe "concerns" do
    subject { instance.public_send(would_be_overrided_method, attachable) }

    let(:would_be_overrided_method) { :attachable_filename }
    let(:attachable) { png_file }
    let(:expected_clients_method_returned_value) { "client's concern method returned value" }

    it "does not override the app's concerns" do
      assert_equal(subject, expected_clients_method_returned_value)
    end
  end

  describe "mime_type initializers" do
    # This test is linked with:
    # validates :asv_test, content_type: 'application/asv_test'
    # If not working, it would throw an error at the app initialization because
    # of our validator check_validity! method.
    it "allows the developer to define its own custom marcel mime types" do
      assert_equal(Marcel::MimeType.for(declared_type: "application/asv_test"), "application/asv_test")
    end
  end

  describe "services" do
    # Uncomment this after having uncommented the S3 service in test_helper.rb
    #
    # describe "digitalocean" do
    #   subject { instance }

    #   it "works fine with the digitalocean service" do
    #     subject.digitalocean.attach(png_file)
    #   end
    # end
  end
end
