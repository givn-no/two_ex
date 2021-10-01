defmodule Tillit.Types do
  @type barcode :: %{
          optional(:value) => String.t(),
          :type => String.t()
        }

  @type line_item_product :: %{
          optional(:brand) => String.t(),
          optional(:categories) => [String.t()],
          optional(:barcodes) => [barcode()],
          optional(:part_number) => String.t()
        }

  @type line_item_type :: :DIGITAL | :PHYSICAL | :SHIPPING | :GIFTCARD | :SERVICE

  @type new_line_item :: %{
          :name => String.t(),
          :description => String.t(),
          optional(:discount_amount) => String.t(),
          :gross_amount => String.t(),
          :net_amount => String.t(),
          :quantity => number(),
          :unit_price => String.t(),
          :tax_amount => String.t(),
          :tax_rate => String.t(),
          :tax_class_name => String.t(),
          :quantity_unit => String.t(),
          optional(:image_url) => String.t(),
          optional(:product_page_url) => String.t(),
          :type => line_item_type(),
          optional(:details) => line_item_product(),
          optional(:prototype_id) => String.t()
        }

  @type representative :: %{
          :first_name => String.t(),
          :last_name => String.t(),
          :phone_number => String.t(),
          optional(:email) => String.t()
        }

  @type company :: %{
          :country_prefix => String.t(),
          :organization_number => String.t(),
          :company_name => String.t(),
          optional(:website) => String.t()
        }

  @type buyer :: %{
          :representative => representative(),
          :company => company()
        }

  @type bank_account :: %{
          :bban => String.t() | nil,
          :iban => String.t() | nil,
          :bic => String.t() | nil,
          :country_code => String.t() | nil,
          :branch_sort_code => String.t() | nil,
          :local_acount_number => String.t() | nil,
          :organization_name => String.t() | nil,
          :organization_number => String.t() | nil,
          :description => String.t() | nil
        }

  @type invoice_details :: %{
          optional(:payee) => bank_account(),
          optional(:payment_reference) => String.t(),
          optional(:payment_reference_type) => String.t(),
          :payment_reference_message => String.t(),
          :payment_reference_ocr => String.t(),
          :due_in_days => integer(),
          optional(:invoice_number) => String.t(),
          optional(:due_date) => String.t()
        }

  @type invoice_type :: :FUNDED_INVOICE | :DIRECT_INVOICE

  @type merchant_urls :: %{
          optional(:merchant_confirmation_url) => String.t(),
          optional(:merchant_cancel_order_url) => String.t(),
          optional(:merchant_edit_order_url) => String.t(),
          optional(:merchant_order_verification_failed_url) => String.t(),
          optional(:merchant_invoice_url) => String.t(),
          optional(:merchant_shipping_document_url) => String.t()
        }

  @type shipping_details :: %{
          optional(:tracking_number) => String.t(),
          optional(:carrier_name) => String.t(),
          optional(:expected_delivery_date) => String.t(),
          optional(:carrier_tracking_url) => String.t()
        }

  @type address :: %{
          :organization_name => String.t(),
          :street_address => String.t(),
          :postal_code => String.t(),
          :city => String.t(),
          :region => String.t(),
          :country => String.t(),
          optional(:references) => address_references()
        }

  @type address_references :: %{
          optional(:co) => String.t(),
          optional(:reference) => String.t(),
          optional(:attn) => String.t()
        }

  @type new_order :: %{
          :gross_amount => String.t(),
          :net_amount => String.t(),
          :currency => String.t(),
          optional(:discount_amount) => String.t(),
          optional(:discount_rate) => String.t(),
          :tax_amount => String.t(),
          :invoice_type => invoice_type(),
          optional(:recurring) => boolean(),
          :buyer => buyer(),
          optional(:buyer_department) => String.t(),
          optional(:buyer_project) => String.t(),
          :line_items => [new_line_item()],
          :merchant_order_id => String.t(),
          optional(:merchant_reference) => String.t(),
          optional(:merchant_additional_info) => String.t(),
          optional(:invoice_details) => invoice_details(),
          optional(:merchant_id) => String.t(),
          optional(:merchant_urls) => merchant_urls(),
          optional(:shipping_details) => shipping_details(),
          optional(:original_order_id) => String.t(),
          optional(:order_note) => String.t(),
          :billing_address => address(),
          :shipping_address => address(),
          optional(:date_fulfilled) => String.t(),
          optional(:tracking_id) => String.t()
        }

  @type order :: %{
          :id => String.t(),
          :gross_amount => String.t(),
          :net_amount => String.t(),
          :currency => String.t(),
          optional(:discount_amount) => String.t(),
          optional(:discount_rate) => String.t(),
          :tax_amount => String.t(),
          :invoice_type => invoice_type(),
          optional(:recurring) => boolean(),
          :buyer => buyer(),
          optional(:buyer_department) => String.t(),
          optional(:buyer_project) => String.t(),
          :line_items => [new_line_item()],
          :merchant_order_id => String.t(),
          optional(:merchant_reference) => String.t(),
          optional(:merchant_additional_info) => String.t(),
          optional(:invoice_details) => invoice_details(),
          optional(:merchant_id) => String.t(),
          optional(:merchant_urls) => merchant_urls(),
          optional(:shipping_details) => shipping_details(),
          optional(:original_order_id) => String.t(),
          optional(:order_note) => String.t(),
          :billing_address => address(),
          :shipping_address => address(),
          optional(:date_fulfilled) => String.t(),
          optional(:tracking_id) => String.t(),
          # server-populated fields
          :state => String.t(),
          :status => String.t(),
          :date_created => String.t(),
          :date_updated => String.t(),
          :merchant_id => String.t(),
          :payment_url => String.t(),
          :invoice_url => String.t(),
          :event_log_url => String.t()
        }

  @type new_order_intent :: %{
          :gross_amount => String.t(),
          optional(:invoice_type) => invoice_type(),
          :currency => String.t(),
          :line_items => [new_line_item()],
          :buyer => buyer(),
          :merchant_id => String.t()
        }

  @type order_intent :: %{
          :gross_amount => String.t(),
          optional(:invoice_type) => invoice_type(),
          :currency => String.t(),
          :line_items => [new_line_item()],
          :buyer => buyer(),
          :merchant_id => String.t(),
          # server-populated fields
          :decline_reason => String.t(),
          :approved => boolean(),
          :tracking_id => String.t() | nil
        }

  @type order_verification :: %{
          # Enum: VERIFIED, UNVERIFIED
          :verification_status => String.t(),
          optional(:verification_method) => String.t(),
          optional(:verified_on) => String.t()
        }
end
