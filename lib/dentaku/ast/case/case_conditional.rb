module Dentaku
  module AST
    class CaseConditional < Node
      attr_reader :when,
                  :then

      def begin_token=(*)
      end

      def begin_token
        @when.begin_token
      end

      def initialize(when_statement, then_statement)
        @when = when_statement
        unless @when.is_a?(AST::CaseWhen)
          raise ParseError, "Expected first argument to be a CaseWhen, was (#{when_statement.repr})"
        end
        @then = then_statement
        unless @then.is_a?(AST::CaseThen)
          raise ParseError, "Expected second argument to be a CaseThen, was (#{then_statement.repr})"
        end
      end

      def repr
        "(#{@when.repr} #{@then.repr})"
      end

      def dependencies(context={})
        @when.dependencies(context) + @then.dependencies(context)
      end
    end
  end
end
