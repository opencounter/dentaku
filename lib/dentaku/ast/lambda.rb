require_relative 'node'

module Dentaku
  module AST
    class Lambda < Node
      attr_reader :arguments, :body
      def initialize(arguments, body)
        # list of strings
        @arguments = arguments

        # another node
        @body = body
      end

      def children
        [@body]
      end

      def repr
        "(#{@arguments.join(" ")} => #{@body.repr})"
      end

      def generate_constraints(context)
        el_types = @arguments.map { |a| Type::Expression.make_variable('arg') }
        ret_type = Type::Expression.make_variable('ret')
        context.add_constraint!([:syntax, self], [:param, :lambda, [ret_type, *el_types]], Type::Reason.literal(self))

        context.with_environment(Hash[@arguments.zip(el_types)]) do
          context.add_constraint!([:syntax, @body], ret_type, Type::Reason.lambda_return(@body))
          @body.generate_constraints(context)
        end
      end

      def free_vars
        @free_vars ||= free_vars_for(self)
      end

      def value
        closure = Calculator.current.capture_env(free_vars)
        lambda do |*args|
          env = closure.merge(Hash[@arguments.zip(args)])

          Calculator.current.bind(env) do
            @body.evaluate
          end
        end
      end

    private
      def free_vars_for(node)
        case node
        when AST::Identifier then node.identifier
        when AST::Lambda then free_vars_for(node.body) - node.arguments
        else node.children.flat_map(&method(:free_vars_for))
        end
      end
    end
  end
end
