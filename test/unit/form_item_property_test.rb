require 'test_helper'

class FormItemPropertyTest < ActiveSupport::TestCase
  fixtures :forms, :form_lines

  class Foo < FormItem
    has_properties :known_property => ["test", "I know this!"]
    def self.concrete_item?; true; end
  end

  def test_validate
    foo = Foo.new(:form_line => form_lines(:personal_line1), :form => form_lines(:personal_line1).line_group)
    assert foo.save

    prop = FormItemProperty.new(:name => "unknown_property", :form_item => foo, :value => "whatever")
    assert !prop.save
    assert prop.errors[:name].any?
    prop.name = "known_property"
    assert prop.save!

    prop = FormItemProperty.new(:name => "known_property", :value => "foo")
    assert !prop.save
    assert prop.errors[:form_item].any?
    prop.form_item = foo
    assert prop.save!
  end
end
