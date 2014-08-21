require 'test_helper'

include CQL

class CQLTest < ActiveSupport::TestCase
  def assert_cql(val, str)
    assert_equal(val, CQL::parse(str))
  end
  def assert_cql_eval(val, ast, vars)
    assert_equal(val, CQL::eval(ast, vars))
  end
  def assert_cql_error(str)
    assert_raises(TypeError) { CQL::parse(str) }
  end

  def test_empty_expr
    assert_cql(true, '')
  end

  def test_boolean_expr
    assert_cql(true, 'true')
    assert_cql(false, 'false')
  end

  def test_string_expr
    assert_cql("hello", '"hello"')
  end

  def test_numeric_expr
    assert_cql(1.0, '1')
    assert_cql(2.5, '2.5')
    assert_cql(-0.1, '-0.1')
  end

  def test_infix_operators
    assert_cql([:+, 1.0, 2.0], '1+2')
    assert_cql([:"!=", 1.0, [:*, 2.0, 3.0]], '1<>2*3')
    assert_cql([:+, [:*, 1.0, 2.0], 3.0], '1*2+3')
    assert_cql([:+, 1.0, [:*, 2.0, 3.0]], '1+2*3')
    assert_cql([:and, [:<, 1.0, 3.0], [:>, 1.0, 2.0]], '1<3 and 1>2')
    assert_cql([:or, [:and, [:<, 1.0, 3.0], [:>, 1.0, 2.0]], [:min, 1.0, 2.0]], '1<3 and 1>2 OR min(1, 2)')
    assert_cql([:or, [:<, 1.0, 3.0], [:and, [:>, 1.0, 2.0], [:min, 1.0, 2.0]]], '1<3 or 1>2 and min(1, 2)')
  end

  def test_prefix_operands
    assert_cql([:min, 1.0, 2.0, 3.0], 'min(1, 2, 3)')
    assert_cql([:max, 1.0, 2.0, 3.0], 'MAX(1, 2, 3)')
    assert_cql_error('nonexistantprocedurename(1, 2)')
    assert_cql_error('min(1')
    assert_cql_error('min(1,')
  end

  def test_complex_expressions
    assert_cql([:min, 1.0, [:+, 2.0, 3.0]], 'min(1, 2 + 3)')
    assert_cql([:min, [:*, 1.0, [:-, 4.0, 3.0]], [:+, 2.0, 3.0]], 'min(1 * (4 - 3), 2 + 3)')
    assert_cql([:>, [:min, [:*, 1.0, [:-, 4.0, 3.0]]], [:max, [:+, 2.0, 3.0]]], 'min(1 * (4 - 3)) > max(2 + 3)')
    assert_cql([:min, [:>, [:"=", 1.0, [:-, 4.0, 3.0]], [:max, [:+, 2.0, 3.0]]]], 'min((1 = (4 - 3)) > max(2 + 3))')
  end

  def test_variables
    assert_cql([:min, :a, :b], 'min(a, b)')
    assert_cql([:min, :foo, :bar], 'min(foo, bar)')
    assert_cql([:min, :foo1, :bar2], 'min(foo1, bar2)')
    assert_cql([:not_in, :a, :b], 'a NOT IN b')
  end

  def test_eval
    assert_cql_eval(50, [:min, :a, :b], {:a => 50, :b => 100})
    assert_cql_eval(false, [:>, :a, 10], {:a => 5})
    assert_cql_eval(true, [:>, :a, 10], {:a => 50})
    assert_cql_eval(true, [:in, "foo", :a], {:a => ["foo"]})
    assert_cql_eval(true, [:not_in, "foo", :a], {:a => ["bar"]})
    assert_cql_eval(false, [:or, false, false], {})
    assert_cql_eval(true, [:or, false, true], {})
    assert_cql_eval(true, [:or, true, false], {})
    assert_cql_eval(true, [:or, true, true], {})
  end

  def test_eval_nil_propagates
    assert_cql_eval(nil, [:<, :a, :b], {:a => 50})
  end

  def test_variable_extraction
    assert_equal [], CQL::used_variables(true)
    assert_equal [], CQL::used_variables([:+, 1, 2])
    assert_equal [:a], CQL::used_variables([:+, 1, :a])
    assert_equal [:a, :b], CQL::used_variables([:+, 1, [:-, :a, :b]])
    assert_equal [:a, :b, :c], CQL::used_variables([:+, [:min, :a, 1], [:-, :b, :c]])
  end
end
