class FormControlCell < FormItemCell
  include ActionView::Helpers::RawOutputHelper
  def label
    raw("<div class='label-wrapper' style='position: absolute; top: 0; right: 100%; text-align: right;'><label>#{ERB::Util.html_escape @item.get_property_value(:label)}</label></div>")
  end
end
