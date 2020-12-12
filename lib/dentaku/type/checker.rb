module Dentaku
  module Type
    class Checker
      class UnboundIdentifiers < StandardError
        attr_reader :identifiers, :type_solution
        def initialize(identifiers, type_solution)
          @identifiers = identifiers
          @type_solution = type_solution
          @unbound_types = @identifiers.map do |ast|
            begin
              constraint = @type_solution[Expression.syntax(ast)]
              constraint.rhs.resolve.repr
            rescue KeyError
              '(unknown type)'
            rescue
              binding.pry
            end
          end
        end

        def message
          ids_and_types = @identifiers.zip(@unbound_types).map do |(id, type_repr)|
            "#{id.repr}:#{type_repr}"
          end.join(', ')

          "UnboundIdentifiers (#{ids_and_types})"
        end
      end

      attr_reader :constraints

      def initialize(&resolver)
        @resolver = resolver
      end

      def reset!
        @constraints = []
        @unbound = []
      end

      def resolve_identifier(identifier)
        type = @resolver.call(identifier)

        if type.nil?
          @unbound << identifier
          return Expression.make_variable("unbound-#{identifier.identifier}")
        end

        Expression.from_sexpr(type)
      end

      def add_constraint!(lhs, rhs, reason)
        #TODO: why does this happen (occurs in OC expression spec)
        lhs = ":#{lhs}" if lhs.is_a?(Symbol)
        rhs = ":#{rhs}" if rhs.is_a?(Symbol)

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

        if @unbound.any?
          raise UnboundIdentifiers.new(@unbound, solutions)
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
