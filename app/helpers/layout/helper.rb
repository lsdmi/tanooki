# frozen_string_literal: true

module Layout
  # Composes layout helpers: page context, stylesheets, adult gate, SweetAlert, flash toasts, fragment cache keys.
  module Helper
    include PageContextHelper
    include StylesheetsHelper
    include AdultContentHelper
    include SweetAlertHelper
    include FlashToastHelper
    include TinymceAssetsHelper
    include LayoutFragmentKeysHelper
    include TurboDriveHelper
  end
end
