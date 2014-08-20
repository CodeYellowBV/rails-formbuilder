# Parse options string.  This has the format:
#
#  # root_item
#  og. simple options
#  ## The inlet temperature
#  ** item1: the first value
#  og. more options
#  ** item2
#  ## item3:value2
#  og. og. sub-options to 'more options'
#  ### This one has a colon \: here : val2
#  ### item4
#
# This results in:
# [{:name => "root_item", :value => 0},
#  ['simple options', {:name => 'The inlet temperature', :value => 1},
#                     {:name => "item1", :value => "the first value", :default => true}]
#  ['more options', {:name => 'item2', :default => true},
#                   {:name => 'item3', :value => 'value2'},
#                   ["sub-options to 'more options'", {:name => 'This has one colon : here', :value => 'val2'},
#                                                     {:name => 'item4'}]]]]
# XXX The output data structure is a little brittle
class OptionsParser
start options

rule
  options:
    option_entry more_options { return [val[0], *val[1]] }
  | /* none */ { return [] }

  more_options:
    NL options { return val[1] }
  | /* none */

  option_entry:
    item
  | group

  group:
    OPTGROUP ws more_optgroup freeform_name { return {:group_depth => val[2], :name => val[3]} }

  # Count group nesting level ("og. og. og." -> level 3)
  more_optgroup:
    OPTGROUP ws more_optgroup { return val[3] + 1 }
  | /* none */ { return 1 }

  # A "freeform" name may include "special" tokens
  freeform_name:
    NAME ws freeform_name_suffix { return val.join() }

  freeform_name_suffix:
    NAME ws freeform_name_suffix { return val.join() }
  | COLON ws freeform_name_suffix { return val.join() }
  | ITEM ws freeform_name_suffix { return val.join() }
  | DEFAULT_ITEM ws freeform_name_suffix { return val.join() }
  | /* none */ { return "" }

  # Almost freeform, except no COLON
  noncolon_name:
    NAME ws noncolon_name_suffix { return val.join() }

  noncolon_name_suffix:
    NAME ws noncolon_name_suffix { return val.join() }
  | ITEM ws noncolon_name_suffix { return val.join() }
  | DEFAULT_ITEM ws noncolon_name_suffix { return val.join() }
  | /* none */ { return "" }

  item:
    ITEM ws noncolon_name item_value {
    return {:name => val[2], :default => false, :value => val[3], :item_depth => val[0].length }
  }
  | DEFAULT_ITEM ws noncolon_name item_value {
    return {:name => val[2], :default => true, :value => val[3], :item_depth => val[0].length }
  }

  item_value:
    COLON freeform_name { return val[1] }
  | /* none */ { @item_id += 1; return @item_id.to_s }

  ws:
    SPACE { return val[0] }
  | /* none */ { return "" }
end

---- inner ----

def parse(str, allow_nested_groups = false)
  @str = str.strip

  @item_id = 0
  @allow_nested_groups = allow_nested_groups

  @parse_result = do_parse()
  make_nested_result(0, 0)[0]
end

def make_nested_result(pos, depth)
  result = []
  while true do
    entry = @parse_result[pos]
    if entry.nil? 
      return [result, pos]
    elsif entry[:group_depth]  # Is it a group?
      raise TypeError, "You can't currently nest groups for this type of form element" unless @allow_nested_groups || entry[:group_depth] <= 1
      if entry[:group_depth] <= depth # let the caller handle this
        return [result, pos]
      else
        res = make_nested_result(pos + 1, entry[:group_depth])
        result << res[0].unshift(entry[:name])
        pos = res[1]
      end
    else # item
      if entry[:item_depth] > depth + 1
        raise TypeError, "Item too deep for option groups: #{entry[:name]}"
      elsif entry[:item_depth] < depth + 1 # caller can handle this
        return [result, pos]
      else
        result << entry
        pos += 1
      end
    end
  end
end

def next_token
  if @str.size > 0
    case @str
    when /\A[\r\n]+/
      ret = [:NL, $&]
    when /\Aog\./
      ret = [:OPTGROUP, $&]
    when /\A[*]+/
      ret = [:DEFAULT_ITEM, $&]
    when /\A#+/
      ret = [:ITEM, $&]
    when /\A[^ \n\r:]+/
      ret = [:NAME, $&]
    when /\A:/
      ret = [:COLON, $&]
    when /\A[\t ]+/
      ret = [:SPACE, $&]
    else
      raise "Unrecognised symbol in string: #{@str.inspect}"
    end
    @str = $'
  else
    ret = [false, '$end']
  end
  return ret
end

def on_error(token_id, error_value, value_stack)
  raise TypeError.new("Unexpected '#{error_value}' before '#{@str}'")
end
