class ListControlCell < FormControlCell
  def render_options_property; render; end

  def render_list
    @list = options[:list]
    render
  end

  def render_edit_list
    @list = options[:list]
    render
  end
end
