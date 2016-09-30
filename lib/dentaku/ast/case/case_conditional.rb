module Dentaku
  module AST
    class CaseConditional < Node
      attr_reader :when,
                  :then

      def initialize(when_statement, then_statement)
        @when = when_statement
        unless @when.is_a?(AST::CaseWhen)
          raise "Expected first argument to be a CaseWhen, was (#{when_statement.repr})"
        end
        @then = then_statement
        unless @then.is_a?(AST::CaseThen)
          raise "Expected second argument to be a CaseThen, was (#{then_statement.repr})"
        end
      end

      def dependencies(context={})
        @when.dependencies(context) + @then.dependencies(context)
      end
    end
  end
end
