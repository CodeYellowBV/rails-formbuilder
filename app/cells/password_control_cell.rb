# A text control which accepts only passwords
class PasswordControlCell < TextControlCell
  include ActionView::Helpers::OutputSafetyHelper
  def show_body
    raw("<input type='password' value='' />")
  end

  def edit_response_body
    if @item_value
      value = @item_value.value
    else
      value = @item.default_value
    end
    raw("<input type='password' value='#{ERB::Util.html_escape(value)}' />")
  end
end
