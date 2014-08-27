class TextControlCell < FormControlCell
  include ActionView::Helpers::OutputSafetyHelper
  def show_body
    raw("<input type='text' value='' />")
  end

  def edit_response_body
    if @item_value
      value = @item_value.value
    else
      value = @item.default_value
    end
    raw("<input type='text' name='form_items[#{@item.id}]' value='#{ERB::Util.html_escape(value)}' />")
  end
end
