module ImportProductsHelper
  def label_products_import import
    states = {
      'created' => 'default',
      'failed' => 'danger',
      'completed' => 'primary',
      'importing' => 'info',
      'started' => 'info',
      'parsed' => 'success',
    }
    raw("<span class='label label-#{states[import.state.downcase]}'>#{t(import.state, :scope => "product_import.state")}</span>")
  end
end
