class FormGroupCell < FormItemCell
  # FormGroups don't make a difference between editing or viewing
  def edit_response
    render_state :show
  end
end
