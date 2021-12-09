require_relative 'case/case_conditional'
require_relative 'case/case_when'
require_relative 'case/case_then'
require_relative 'case/case_switch_variable'
require_relative 'case/case_else'

module Dentaku
  module AST
    class Case < Node
      def self.precedence
        1
      end

      def initialize(switch, clauses, else_)
        @switch = switch
        @clauses = clauses
        @else = else_
      end

      def children
        [@switch, @clauses, @else].compact.flatten
      end

      def value
        switch_value = @switch.nil? ? true : @switch.evaluate

        @clauses.each do |clause|
          when_, then_ = clause
          if when_.evaluate === switch_value
            return then_.evaluate
          end
        end

        if @else
          return @else.evaluate
        else
          raise NoMatch.new(self, switch_value)
        end
      end

      def dependencies(context={})
        out = []
        out << @switch.dependencies(context) if @switch
        out << @clauses.flatten.map { |c| c.dependencies(context) }
        out << @else.dependencies(context) if @else
        out.flatten
      end

      def generate_constraints(context)
        result_type = Type::Expression.make_variable('case')
        @switch.generate_constraints(context) if @switch

        @clauses.each_with_index do |(when_, then_), index|
          when_.generate_constraints(context)
          if @switch.nil?
            context.add_constraint!([:syntax, when_],
                                    [:concrete, :bool],
                                    [:case_when, self, index])
          elsif when_.is_a?(AST::Range)
            context.add_constraint!([:syntax, @switch],
                                    [:concrete, :numeric],
                                    [:case_when_range, self, index])
          else
            context.add_constraint!([:syntax, @switch],
                                    [:syntax, when_],
                                    [:case_when, self, index])
          end

          then_.generate_constraints(context)
          context.add_constraint!([:syntax, then_],
                                  result_type,
                                  [:case_then, self, index])
        end

        if @else
          @else.generate_constraints(context)
          context.add_constraint!([:syntax, @else],
                                  result_type,
                                  [:case_else, self])
        end

        context.add_constraint!([:syntax, self],
                                result_type,
                                [:case_return, self])
      end

      def repr
        out = ''
        out << 'CASE '
        out << "SWITCH(#{@switch.repr})" if @switch
        @clauses.each do |(when_, then_)|
          out << "\n"
          out << ' WHEN ' << when_.repr
          out << "\n"
          out << ' THEN ' << then_.repr
        end
        out << "\n"
        out << ' ELSE ' << @else.repr if @else
        out << "\n"
        out << ' END'

        out
      end
    end
  end
end
