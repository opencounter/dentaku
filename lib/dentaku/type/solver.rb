require 'set'

module Dentaku
  module Type
    class TypeCheckError < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
      end

      def message
        @errors.map { |error|
          "Expected #{error.lhs.repr} but got #{error.rhs.repr} #{error.reason.repr}"
        }.join("\n")
      end
    end

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
          @constraints.each { |c| puts "-> #{c.repr}" }
        end

        while @constraints.any?
          constraint = @constraints.pop
          process_constraint(constraint)
        end

        if @debug
          @solution_set.each { |c| puts "=> #{c.repr}" }
        end

        raise TypeCheckError.new(@errors) if @errors.any?

        @solution_set
      end

      private

      def solve_for?(expression)
        return true if expression.syntax?
        return true if expression.variable? && !@free_vars_set.include?(expression.expression_hash)
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
            dictionary: ->(keys, types) {
              constraint.rhs.cases(
                dictionary: ->(other_keys, other_types) {
                  if other_keys == keys
                    types.zip(other_types).each_with_index do |(lhs, rhs), index|
                      push(Constraint.new(lhs, rhs, Reason.dictionary_key(constraint, keys[index])))
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
        end
      end

      def error!(constraint)
        if @debug
          # binding.pry
          puts "!> #{constraint.repr}"
        end

        @errors << constraint
      end
    end
  end
end
