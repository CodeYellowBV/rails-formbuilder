class FormStaticCell < FormItemCell
  # There's nothing to edit in a static view
  def edit_response
    render :view => 'show'
  end

  def show_response
    render :view => 'show'
  end
end
