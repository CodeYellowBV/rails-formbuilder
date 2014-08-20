class ImageStaticCell < FormStaticCell
  include ActionView::Helpers::RawOutputHelper

  def render_image_property
    self.render_state(:render_property_label) + raw("<input id='#{property_id}' type='file' name='properties[#{@property.name}]' />")
  end

  # A little bit hacky, but it works :)
  def render_data
    if data = @item.get_property_value(:image)
      @controller.send(:send_data,
                       data,
                       :filename => @item.get_property_value(:filename),
                       :type => @item.get_property_value(:content_type),
                       :disposition => "inline")
   else
      ""
   end
  end

  def render_filename_property; ""; end
  def render_content_type_property; ""; end

  def xml_export_image_property
    ActiveSupport::Base64.encode64(ActiveSupport::Gzip.compress(@property.value))
  end

  def xml_import_image_property
    @property.value = ActiveSupport::Gzip.decompress(ActiveSupport::Base64.decode64(@xml.text.to_s))
    ""
  end
end
