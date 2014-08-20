# Conditional Query Language stuff
#
# Modeled after SQL, CQL is like the WHERE part of a SQL query.
# In formbuilder, it is a mini-language that allows one to express
# when a form item is visible, conditionally based on other items.
module CQL
  # This contains the procedures known to CQL. Remember to always propagate
  # nil values, as unresolved variables shouldn't cause the application
  # to come crashing down.
  class Procedures
    instance_methods.each { |m| undef_method m unless m =~ /^__/ }

    [:"<", :">", :"<=", :">=", :"-", :"+", :"/", :"*"].each do |method|
      define_method(method) do |a, b|
        if a.respond_to?(method) and b.respond_to?(method)
          a.send(method, b)
        else
          nil
        end
      end
    end

    define_method(:"=")  do |a, b|
      if a.respond_to?(:"==") and b.respond_to?(:"==")
        a == b
      else
        nil
      end
    end
    define_method(:"!=")  do |a, b|
      if a.respond_to?(:"==") and b.respond_to?(:"==")
        a != b
      else
        nil
      end
    end

    define_method(:and) do |*args|
      retval = true # AND will succeed unless a false/NULL value is found
      args.each do |arg|
        # We can stop at the moment we find nil or a false value
        if arg.nil?
          retval = nil
          break
        elsif !arg
          retval = false
          break
        end
      end
      return retval
    end

    define_method(:or) do |*args|
      retval = false # OR will fail unless a true/NULL value is found
      args.each do |arg|
        # We can stop at the moment we find nil or a true value
        if arg.nil?
          retval = nil
          break
        elsif arg
          retval = true
          break
        end
      end
      return retval
    end

    def in(a, b)
      if !a.nil? && b.respond_to?(:include?)
        b.include?(a)
      else
        nil
      end
    end

    def not_in(a, b)
      if !a.nil? && b.respond_to?(:include?)
        !b.include?(a)
      else
        nil
      end
    end

    def min(*args)
      args.compact.min
    end

    def max(*args)
      args.compact.max
    end
  end
  
  def self.procs
    @procs ||= Procedures.new
  end

  # Parse the CQL expression string into an abstract syntax tree (AST)
  def self.parse(str)
    @parser ||= CQLParser.new()
    @parser.parse(str)
  end

  # Evaluate the AST, returning the value returned by the outermost procedure call
  def self.eval(ast, env)
    if ast.is_a?(Array)
      # Assume ast[0] is a symbol with an operator and ast[1..-1] are operands.
      # Currently no nesting is allowed at the operator position.
      procs.__send__(ast[0], *(ast[1..-1].map {|x| self.eval(x, env)}))
    elsif ast.is_a?(Symbol)
      env[ast]
    else
      ast
    end
  end

  # Get all the variables used in an AST. This is useful when we want
  # to give a warning about undefined variables, for example.
  def self.used_variables(ast)
    if ast.is_a?(Array)
      (ast[1..-1].map {|x| self.used_variables(x)}).flatten
    elsif ast.is_a?(Symbol)
      [ast]
    else
      []
    end
  end
end
