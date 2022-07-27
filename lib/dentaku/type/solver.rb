require 'set'

module Dentaku
  module Type
    class Solver
      def initialize(constraints, options={})
        @constraints = constraints
        @solution_set = SolutionSet.new
        @errors = []
        @debug = options[:debug]
        @free_vars = options[:free_vars] || []
        @free_vars_set = Set.new(@free_vars.map(&:expression_hash))
      end

      def self.solve(constraints, options={})
        new(constraints, options).solve
      end

      def solve
        if @debug
          @free_vars.each { |v| puts "free #{v.repr}" }
          @constraints.each { |c| puts "-> #{c.repr} (#{c.reason.repr})" }
        end

        while @constraints.any?
          constraint = @constraints.pop
          process_constraint(constraint)
        end

        if @debug
          @solution_set.each { |c| puts "=> #{c.repr}" }
        end

        [@solution_set, @errors]
      end

      private

      def solve_for?(expression)
        return true if expression.syntax?
        return true if expression.variable? && !@free_vars_set.include?(expression.expression_hash)
        return true if expression.key_of?
        return false
      end

      def process_constraint(constraint)
        return if constraint.lhs == constraint.rhs

        if @debug
          puts ">> #{constraint.repr}"
        end

        if solve_for?(constraint.lhs)
          solve_for(constraint)
        elsif solve_for?(constraint.rhs)
          solve_for(constraint.swap)
        else
          constraint.lhs.cases(
            param: ->(name, arguments) {
              constraint.rhs.cases(
                param: ->(other_name, other_arguments) {
                  if name != other_name || arguments.size != other_arguments.size
                    error!(constraint)
                  else
                    arguments.zip(other_arguments).each_with_index do |(lhs, rhs), index|
                      push(Constraint.new(lhs, rhs, Reason.destructure(constraint, index)))
                    end
                  end
                },
                other: -> { error!(constraint) }
              )
            },
            struct: ->(keys, types) {
              constraint.rhs.cases(
                struct: ->(other_keys, other_types) {
                  if other_keys == keys
                    types.zip(other_types).each_with_index do |(lhs, rhs), index|
                      push(Constraint.new(lhs, rhs, Reason.struct_key(constraint, keys[index])))
                    end
                  else
                    error!(constraint)
                  end
                },
                other: -> { error!(constraint) }
              )
            },
            other: -> { error!(constraint) },
          )
        end

      end

      def push(constraint)
        @constraints << constraint
      end

      def solve_for(constraint)
        if @solution_set.has_key?(constraint.lhs)
          push(constraint & @solution_set[constraint.lhs])
        else
          if @debug
            puts "%> #{constraint.repr}"
          end

          @solution_set.add_solution(constraint)
          @solution_set.map_constraints!(&method(:simplify))
        end
      end

      def substitute(constraint)
        simplify(@solution_set.raw_substitute(expr.rhs), constraint)
      end

      def simplify(constraint)
        constraint.map_rhs do |expr|
          simplify_expr(constraint, expr)
        end
      end

      def simplify_expr(constraint, expr)
        default = -> { expr.map { |e| simplify_expr(constraint, e) } }

        expr.cases(
          key_of: ->(struct, key) {
            struct.cases(
              param: ->(name, args) {
                as_struct = DECLARED_TYPES[name].structable

                return simplify_error!(expr, StructError.new(constraint)) unless as_struct.key?(key)

                Expression.from_sexpr(as_struct[key])
              },
              struct: ->(keys, types) {
                idx = keys.find_index(key)
                return simplify_error!(expr, StructError.new(constraint)) if idx.nil?

                simplify_expr(constraint, types[idx])
              },
              other: default
            )
          },
          other: default
        )
      end

      def simplify_error!(expr, error)
        if @debug
          puts "!> can't simplify #{expr.repr}"
        end

        @errors << error

        Expression.make_variable('invalid')
      end

      def error!(constraint)
        if @debug
          puts "!> #{constraint.repr}"
        end

        @errors << TypeMismatch.new(constraint)
      end
    end
  end
end
