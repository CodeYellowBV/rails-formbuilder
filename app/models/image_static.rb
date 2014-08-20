# An simple image field (not a field on which an image can be uploaded by
# the one who fills in the form, but by who makes the form)
class ImageStatic < FormStatic
  has_properties :image => ["Image", ""], :filename => ["Filename", ""], :content_type => ["Content-type", "image/png"]

  def self.concrete_item?; true; end

  # Override this in specific implementations if you want a more rigorous check if the image is allowed.
  # The argument is the full image object as passed by the server.
  def self.allowed_image?(i)
    i.content_type.split("/").first == "image"
  end

  def store_properties(props)
    unless props[:image].blank?
      if self.class.allowed_image?(props[:image])
        props[:content_type] = props[:image].content_type
        props[:filename] = props[:image].original_filename
        props[:image] = props[:image].read
      else
        props.delete(:image)
        props.delete(:content_type)
        props.delete(:filename)
      end
    end
    super(props)
  end
end
