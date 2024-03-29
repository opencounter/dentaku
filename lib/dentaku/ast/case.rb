module Dentaku
  module AST
    class Case < Node
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

          when_.each do |w|
            if w.evaluate === switch_value
              return then_.evaluate
            end
          end
        end

        if @else
          return @else.evaluate
        else
          raise NoMatch.new(self, switch_value)
        end
      end

      def generate_constraints(context)
        result_type = Type::Expression.make_variable('case')
        @switch.generate_constraints(context) if @switch

        @clauses.each_with_index do |(when_, then_), index|
          when_.each do |w|
            w.generate_constraints(context)

            if @switch.nil?
              context.add_constraint!([:syntax, w],
                                      [:concrete, :bool],
                                      [:case_when, self, index])
            elsif w.is_a?(AST::Range)
              context.add_constraint!([:syntax, @switch],
                                      [:concrete, :numeric],
                                      [:case_when_range, self, index])
            else
              context.add_constraint!([:syntax, @switch],
                                      [:syntax, w],
                                      [:case_when, self, index])
            end
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
        out << "SWITCH(#{@switch.repr})\n" if @switch
        @clauses.each do |(when_, then_)|
          out << '(WHEN ' << when_.map(&:repr).join(', ')
          out << ' THEN ' << then_.repr << ')'
          out << "\n"
        end
        out << 'ELSE ' << @else.repr if @else
        out << "\n"
        out << 'END'

        out
      end
    end
  end
end
