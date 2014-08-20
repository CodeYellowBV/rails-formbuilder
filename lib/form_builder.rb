module FormBuilder
  # In order to be able to dynamically generate a toolbox for all
  # FormItem subclasses, we need to store a list of them somewhere.
  #
  # With register_classes you can register your own.  By default
  # the plugin already has a list of known subclasses.
  # The names you pass to this method should be underscored.
  #
  # Example:
  # FormBuilder::register_classes :my_item1, :my_item2
  def self.register_classes(*args)
    @classes ||= []
    @classes = @classes | args.map(&:to_sym)
  end

  self.register_classes(:form_item, :form_static, :form_control, # :form_group,
                        :text_control, :integer_control, :email_control,
                        :password_control, :text_area_control,
                        :informational_static, :list_control, :checkbox_control,
                        :select_control, :multi_select_control, :image_static)


  # Remove any number of classes from the known ones.  Useful if you
  # would like to disable form item types that are shipped with
  # FormBuilder by default.
  #
  # Unregistering a class does not make it unusable for subclassing:
  # you can still borrow code from it.
  def self.unregister_classes(*args)
    @classes ||= []
    @classes = @classes -= args.map(&:to_sym)
  end

  # Returns the classes registered by register_classes
  def self.get_classes
    (@classes || []).map{|k| eval(k.to_s.camelize) }
  end

  # Returns just the classname symbols registered by register_classes
  def self.get_classnames
    @classes || []
  end
end
