module Dentaku
  module Type
    class SolutionSet
      def initialize
        @solutions = {}
      end

      def substitute(expr)
        fetch(expr) do
          expr.map { |e| substitute(e) }
        end
      end

      # e.g. [:syntax, :ast], [:param, :foo, :a1]
      # abstract -> concrete
      def add_solution(constraint)
        constraint = constraint.map_rhs(&method(:substitute))
        add_constraint(constraint)

        map_solutions!(&method(:substitute))
        return self
      end

      def has_key?(expr)
        @solutions.has_key?(expr.expression_hash)
      end

      def add_constraint(constraint)
        @solutions[constraint.lhs.expression_hash] = constraint
      end

      def [](expr)
        @solutions.fetch(expr.expression_hash)
      end

      def fetch(expr, &blk)
        blk ||= lambda { raise KeyError }
        key = expr.expression_hash

        if @solutions.key?(key)
          @solutions[key].rhs
        else
          blk.call
        end
      end

      def map_solutions!(&blk)
        @solutions.keys.each do |key|
          constraint = @solutions[key]
          @solutions[key] = constraint.map_rhs(&blk)
        end
      end

      def map_constraints!(&blk)
        @solutions.keys.each do |key|
          @solutions[key] = blk.call(@solutions[key])
        end
      end

      def resolved_type_of(ast)
        fetch(Expression.syntax(ast)).resolve
      rescue KeyError
        Type.abstract
      end

      def inspect
        "<SolutionSet \n#{@solutions.values.map(&:inspect).join("\n")} >"
      end

      def each(&blk)
        @solutions.values.each(&blk)
      end
    end
  end
end
