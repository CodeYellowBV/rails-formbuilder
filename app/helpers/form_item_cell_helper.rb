module FormItemCellHelper
  def form_item_start(item)
    visible = (@form_response.nil? or @form_response.visible?(item))
    raw("<div id='form-item_#{item.id}' class='form-item element-for-#{item.class.name.underscore} #{'selected' if item.selected}' style='#{render_form_element(item, :positioning_style)} display: #{visible ? 'auto' : 'none'};'><div class='fap-content-wrapper'>")
  end

  def form_item_end(item)
    opts = {
      :dependencies => item.dependencies(@form).map(&:id),
      :dependees => item.dependees(@form).map(&:id)
    }
    raw("</div></div><script type='text/javascript'>new FormItem('form-item_#{item.id}',#{opts.to_json});</script>")
  end

  # XXX TODO: Proper javascript support; don't break the back button (http://developer.apple.com/internet/webcontent/iframe.html)
  def iframe_remote_tag(options = {}, html_options = {}, &proc)
    @counter ||= 0
    @counter += 1
    f = form_tag(options, html_options.merge({:target => "iframe_hack_#{@counter}"}), &proc)
    # Can't use display: none because it breaks in netscape 6 and (older versions of) firefox
    raw("#{f}<iframe id='iframe_hack_#{@counter}' name='iframe_hack_#{@counter}' style='width: 0px; height: 0px; border: 0px'></iframe>")
  end
end
