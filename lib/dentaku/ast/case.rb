require_relative './case/case_conditional'
require_relative './case/case_when'
require_relative './case/case_then'
require_relative './case/case_switch_variable'
require_relative './case/case_else'

module Dentaku
  module AST
    class Case < Node
      def initialize(*nodes)
        @switch = nodes.shift

        unless @switch.is_a?(AST::CaseSwitchVariable)
          raise 'Case missing switch variable'
        end

        @conditions = nodes

        @else = @conditions.pop if @conditions.last.is_a?(AST::CaseElse)

        @conditions.each do |condition|
          unless condition.is_a?(AST::CaseConditional)
            raise "#{condition} is not a CaseConditional"
          end
        end
      end

      def value
        switch_value = @switch.evaluate
        @conditions.each do |condition|
          if condition.when.evaluate === switch_value
            return condition.then.evaluate
          end
        end

        if @else
          return @else.evaluate
        else
          raise "No block matched the switch value '#{switch_value}'"
        end
      end

      def dependencies(context={})
        # TODO: should short-circuit
        @switch.dependencies(context) +
          @conditions.flat_map { |condition| condition.dependencies(context) } +
          @else.dependencies(context)
      end

      def generate_constraints(context)
        var = Type::Expression.make_variable('case')
        @switch.node.generate_constraints(context)

        @conditions.each_with_index do |condition, index|
          condition.when.node.generate_constraints(context)
          case condition.when.node
          when AST::Range
            context.add_constraint!([:syntax, @switch.node], [:concrete, :numeric], [:case_when_range, self, index])
          else
            context.add_constraint!([:syntax, @switch.node], [:syntax, condition.when.node], [:case_when, self, index])
          end

          condition.then.node.generate_constraints(context)
          context.add_constraint!([:syntax, condition.then.node], var, [:case_then, self, index])
        end

        if @else
          @else.node.generate_constraints(context)
          context.add_constraint!([:syntax, @else.node], var, [:case_else, self])
        end
        context.add_constraint!([:syntax, self], var, [:case_return, self])
      end

      def repr
        "case TODO"
      end
    end
  end
end
