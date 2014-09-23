module ApplicationHelper
  # A render_cell variant for any type of form element.  This takes care of correctly
  # passing the element to the correct cell.
  def render_form_element(element, state, opts = {})
    render_cell(element.class.name.underscore, state, opts.merge({:element => element, :form => @form, :form_response => @form_response}))
  end

  # XXX FIXME From Rails.  Not really nice that we need to copy this!  Look into what we did for Libersy
  def formbuilder_image_tag(source, options = {})
    options.symbolize_keys!

    options[:src] = formbuilder_image_path(source)
    options[:alt] ||= File.basename(options[:src], '.*').split('.').first.humanize
    options[:title] ||= options[:alt]

    if options[:size]
      options[:width], options[:height] = options[:size].split("x") if options[:size] =~ %r{^\d+x\d+$}
      options.delete(:size)
    end

    tag("img", options)
  end

  # Override this if you want to override image paths used by form builder
  def formbuilder_image_path(filename)
    if File.exists?("#{Rails.root}/public/plugin_assets/formbuilder/images/#{filename}")
      image_path("/plugin_assets/formbuilder/images/#{filename}")
    else
      image_path(filename)
    end
  end

  def error_list(object)
    if object.errors.empty?
      ""
    else
      raw(object.errors.inject("<ul class='errors'>") do |all, error_pair|
        all + "<li>#{h error_pair[1]}</li>"
      end + "</ul>")
    end
  end
end
