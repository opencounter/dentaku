module Dentaku
  class Missing < StandardError
    attr_reader :ast
  end

  class UnboundVariableError < Missing
    attr_reader :unbound_variables

    def initialize(ast, unbound_variables)
      @ast = ast
      @unbound_variables = unbound_variables
      super("no value provided for variables: #{ unbound_variables.to_a.join(', ') }")
    end
  end

  class EmptyList < Missing
    def initialize(ast)
      @ast = ast
      super("oops, this list was empty: `#{ast.source}`")
    end
  end
end
