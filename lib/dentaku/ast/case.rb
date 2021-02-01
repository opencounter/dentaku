require_relative 'case/case_conditional'
require_relative 'case/case_when'
require_relative 'case/case_then'
require_relative 'case/case_switch_variable'
require_relative 'case/case_else'

module Dentaku
  module AST
    class Case < Node
      def initialize(*nodes)
        @switch = nodes.shift if nodes.first.is_a?(AST::CaseSwitchVariable)

        @conditions = nodes

        @else = @conditions.pop if @conditions.last.is_a?(AST::CaseElse)

        @conditions.each do |condition|
          unless condition.is_a?(AST::CaseConditional)
            raise ParseError.new("`#{condition.repr rescue condition.inspect}' is not a valid CASE condition", condition)
          end
        end
      end

      def children
        [@switch, @conditions, @else].compact.flatten(1)
      end

      def value
        switch_value = @switch.nil? ? true : @switch.evaluate

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
        out = []
        out << @switch.dependencies(context) if @switch
        out << @conditions.flat_map { |c| c.dependencies(context) }
        out << @else.dependencies(context) if @else
        out.flatten
      end

      def generate_constraints(context)
        result_type = Type::Expression.make_variable('case')
        @switch.node.generate_constraints(context) if @switch

        @conditions.each_with_index do |condition, index|
          condition.when.node.generate_constraints(context)
          if @switch.nil?
            context.add_constraint!([:syntax, condition.when.node],
                                    [:concrete, :bool],
                                    [:case_when, self, index])
          elsif condition.when.node.is_a?(AST::Range)
            context.add_constraint!([:syntax, @switch.node],
                                    [:concrete, :numeric],
                                    [:case_when_range, self, index])
          else
            context.add_constraint!([:syntax, @switch.node],
                                    [:syntax, condition.when.node],
                                    [:case_when, self, index])
          end

          condition.then.node.generate_constraints(context)
          context.add_constraint!([:syntax, condition.then.node],
                                  result_type,
                                  [:case_then, self, index])
        end

        if @else
          @else.node.generate_constraints(context)
          context.add_constraint!([:syntax, @else.node],
                                  result_type,
                                  [:case_else, self])
        end

        context.add_constraint!([:syntax, self],
                                result_type,
                                [:case_return, self])
      end

      def repr
        children.map(&:repr).join("\n") << "END"
      end
    end
  end
end
