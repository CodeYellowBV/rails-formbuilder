class TextAreaControlCell < TextControlCell
  def show_body
    raw("<textarea rows='#{@item.get_property_value(:rows)}' cols='#{@item.get_property_value(:cols)}'></textarea>")
  end

  def edit_response_body
    if @item_value
      value = @item_value.value
    else
      value = @item.default_value
    end
    raw("<textarea name='form_items[#{@item.id}]' rows='#{@item.get_property_value(:rows)}' cols='#{@item.get_property_value(:cols)}'>#{ERB::Util.html_escape(value)}</textarea>")
  end
end
