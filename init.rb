require 'form_builder'

# Serve up assets properly (we might want to change this to be more Rails-3'ish in the future)
FileUtils.mkdir_p("#{Rails.root}/public/plugin_assets")
unless File.exists?("#{Rails.root}/public/plugin_assets/formbuilder")
  File.symlink(File.dirname(__FILE__)+'/assets', "#{Rails.root}/public/plugin_assets/formbuilder")
end

# Import an extra method that works just like the controller method
class Cell::Base
  def render_cell_to_string(name, state, opts={})
    cell = Cell::Base.create_cell_for(@controller, name, opts);
    return cell.render_state(state)
  end

  def state_name
    @_action_name
  end
end

# Make this behave as a regular "engine"
Cell::Base.view_paths = Cell::Base.view_paths.dup.push(File.dirname(__FILE__)+'/app/cells')
