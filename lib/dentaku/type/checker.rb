module Dentaku
  module Type
    class Checker
      class UnboundIdentifier < StandardError
        def initialize(identifier)
          @identifier = identifier
        end

        def message
          "UnboundIdentifier (#{@identifier})"
        end
      end

      attr_reader :constraints

      def initialize(&resolver)
        @resolver = resolver
      end

      def reset!
        @constraints = []
      end

      def resolve_identifier(identifier)
        type = @resolver.call(identifier)
        type or raise UnboundIdentifier.new(identifier)
        Expression.from_sexpr(type)
      end

      def add_constraint!(lhs, rhs, reason)
        @constraints << Constraint.new(
          Expression.from_sexpr(lhs),
          Expression.from_sexpr(rhs),
          Reason.from_sexpr(reason)
        )
      end

      def check!(ast, options={})
        reset!
        ast.generate_constraints(self)
        solutions = Solver.solve(@constraints, options)

        solutions.each do |constraint|
          constraint.lhs.cases(
            syntax: -> (ast) { ast.type = constraint.rhs.resolve },
            other: :pass
          )
        end

        solutions
      end
    end

    class FunctionChecker < Checker
      attr_reader :scope, :type_spec
      def initialize(type_spec, &resolver)
        resolver ||= lambda {|*|}
        @scope = {}

        if type_spec.is_a? String
          @type_spec = Syntax.parse_spec(type_spec)
        else
          @type_spec = type_spec
        end

        super() do |variable|
          if variable.identifier =~ /\Aarg:(\d+)\z/
            index = $1.to_i - 1
            type = @type_spec.arg_types[index]
            next nil unless type
            type.resolve_vars(@scope)
          else
            resolver.call(variable)
          end
        end
      end

      def check!(ast, options={})
        reset!
        ast.generate_constraints(self)

        add_constraint!([:syntax, ast], type_spec.return_type.resolve_vars(@scope), [:definition_retval, type_spec, @scope])

        solutions = Solver.solve(@constraints.reverse, options.merge(free_vars: @scope.values))

        reverse_scope = {}
        @scope.each do |name, texpr|
          reverse_scope[[texpr.name, texpr.uniq]] = name
        end

        solutions.each do |constraint|
          constraint.lhs.cases(
            syntax: -> (ast) { ast.type = constraint.rhs.resolve(reverse_scope) },
            other: :pass
          )
        end

        [@scope, solutions]
      end
    end

    class StaticChecker < Checker
      def initialize(map={})
        string_map = {}
        map.each { |k, v| string_map[k.to_s] = v }

        block = lambda { |node| string_map[node.identifier] }
        super(&block)
      end
    end
  end
end
