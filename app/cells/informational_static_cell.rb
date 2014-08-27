class InformationalStaticCell < FormStaticCell
  include ActionView::Helpers::OutputSafetyHelper

  # Render the content as a textarea
  def render_contents_property
    render
  end

  def show_body
    raw(BlueCloth.new(@item.get_property_value(:contents)).to_html)
  end
end
