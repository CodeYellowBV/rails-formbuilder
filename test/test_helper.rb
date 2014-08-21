# Load the normal Rails helper. This ensures the environment is loaded
require 'test_helper'

ActiveSupport::TestCase.fixture_path = File.dirname(__FILE__)+'/fixtures'

class ActiveSupport::TestCase
  def controller
    return @controller if @controller

    @controller = ApplicationController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller.request = @request
    @controller.response = @response
    @controller
  end

  def element_cell_state(element, state, opts={})
    cell = Cell::Base.create_cell_for(self.controller, element.class.name.underscore, opts.merge({:element => element}));

    #self.controller.send :forget_variables_added_to_assigns   # this fixes bug #1, PARTLY.

    cell.render_state(state)
  end
end
