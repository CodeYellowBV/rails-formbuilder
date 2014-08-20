class CQLParser
start none_or_expr

prechigh
  left MULDIV
  left PLUSMIN
  nonassoc IN
  nonassoc CMP
  left AND
  left OR
preclow

rule
  none_or_expr:
    expr
  | /* none */ { return true }

  expr:
    infix_funcall | primary

  primary:
    '(' expr ')' { return val[1] }
  | prefix_funcall
  | value

  infix_funcall:
    expr OR expr { return [:or, val[0], val[2]] }
  | expr AND expr { return [:and, val[0], val[2]] }
  | expr IN expr { return [to_func(val[1]), val[0], val[2]] }
  | expr CMP expr { return [to_func(val[1]), val[0], val[2]] }
  | expr PLUSMIN expr { return [to_func(val[1]), val[0], val[2]] }
  | expr MULDIV expr { return [to_func(val[1]), val[0], val[2]] }

  prefix_funcall:
    IDENTIFIER '(' operands ')' { return [to_func(val[0]), *val[2]] }

  operands:
    expr ',' operands { return [val[0], *val[2]] }
  | expr { return [val[0]] }

  value:
    literal { return val[0] }
  | IDENTIFIER { return val[0].to_sym }

  literal:
    boolean | number | STRING

  number:
    PLUSMIN NUMBER { return (val[0] == '+' ? val[1].to_f : -val[1].to_f) }
  | NUMBER { return val[0].to_f }

  boolean:
    BOOLEAN { return val[0].downcase == "true" }
end

---- inner ----

def parse(str)
  @str = str.strip

  do_parse()
end

def next_token
  if @str.size > 0
    case @str
    when /^\d+(\.\d+)?/
      ret = [:NUMBER, $&]
    when /^[+-]/
      ret = [:PLUSMIN, $&]
    when /^[*\/]/
      ret = [:MULDIV, $&]
    when /^and\b/i
      ret = [:AND, $&]
    when /^or\b/i
      ret = [:OR, $&]
    when /^(not\s+)?in\b/i
      ret = [:IN, $&]
    when /^(true|false)\b/i
      ret = [:BOOLEAN, $&]
    when /^(><|<>|!=)/
      ret = [:CMP, "!="]
    when /^(<=|>=|=|<|>)/
      ret = [:CMP, $&]
    when /^"([^"]+)"/
      ret =[:STRING, $1]
    when /^[a-zA-Z_][a-zA-Z_0-9]*/
      ret = [:IDENTIFIER, $&]
    when /^[(,)]/
      ret = [$&, $&]
    else
      raise "Unrecognised symbol in string: #{@str.inspect}"
    end
    @str = $'
    @str.lstrip!
  else
    ret = [false, '$end']
  end
  return ret
end

def to_func(name)
  name.sub!(/\s+/, '_')
  name.downcase!
  if CQL::Procedures.instance_methods.include?(name)
    name.to_sym
  else
    raise TypeError.new("Unknown procedure '#{name}'")
  end
end

def on_error(token_id, error_value, value_stack)
  raise TypeError.new("Unexpected '#{error_value}' after '#{value_stack.reverse[0..5].reverse}'")
end
