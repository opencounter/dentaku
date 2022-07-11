module Dentaku
  module Type
    class Checker
      attr_reader :constraints

      def initialize(&resolver)
        @resolver = resolver
        @bindings = []
      end

      def reset!
        @constraints = []
        @invalid_asts = []
      end

      def with_environment(env)
        @bindings << env
        yield
      ensure
        @bindings.pop
      end

      def resolve_identifier(identifier)
        name = identifier.identifier
        @bindings.reverse_each do |env|
          return env[name] if env.key?(name)
        end

        resolve_external_identifier(identifier)
      end

      def resolve_external_identifier(identifier)
        type = @resolver.call(identifier)

        if type.nil?
          invalid_ast!(UnboundIdentifier, identifier)
          return Expression.make_variable("unbound-#{identifier.identifier}")
        end

        Expression.from_sexpr(type)
      end

      def invalid_ast!(error_class, ast)
        @invalid_asts << [error_class, ast]
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

        expected_type = options.delete(:expected_type)
        add_constraint!([:syntax, ast], expected_type, [:root, ast]) if expected_type

        solutions, errors = Solver.solve(@constraints, options)

        errors += @invalid_asts.map { |k, a| k.new(a, solutions) }

        # set the "type" attribute on all of the nodes, *even if there
        # were type errors*. worst case sometimes this attribute will
        # be abstract, or nil (if it isn't in the solution set at all).
        solutions.each do |constraint|
          constraint.lhs.cases(
            syntax: -> (ast) { ast.type = constraint.rhs.resolve },
            other: :pass
          )
        end

        if errors.any?
          raise ErrorSet.new(errors)
        end

        solutions
      end
    end

    # [jneen] TODO this is unused and speculative, should not have been merged.
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
