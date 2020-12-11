require 'set'

module Dentaku
  module Type
    class TypeCheckError < StandardError
      attr_reader :location

      def initialize(constraint)
        @constraint = constraint
        @location = extract_range(@constraint.ast_nodes)
      end

      def message
        "Expected #{@constraint.lhs.repr} but got #{@constraint.rhs.repr} #{@constraint.reason.repr}"
      end

      private
      def extract_range(causes)
        return [[0,0], [0,0]] if causes.empty?

        locations = causes.map do |cause|
          case cause
          when Array then cause
          when Token, AST::Node then cause.loc_range
          end
        end
        start_points = locations.map(&:first)
        end_points = locations.map(&:last)
        [start_points.sort.first, end_points.sort.last]
      end

    end

    class TypeCheckErrorSet < StandardError
      attr_reader :errors

      def initialize(constraints)
        @constraints = constraints
        @errors = constraints.map do |constraint|
          TypeCheckError.new(constraint)
        end
      end

      def message
        @errors.map(&:message).join("\n")
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
          @constraints.each { |c| puts "-> #{c.repr} (#{c.reason.repr})" }
        end

        while @constraints.any?
          constraint = @constraints.pop
          process_constraint(constraint)
        end

        if @debug
          @solution_set.each { |c| puts "=> #{c.repr}" }
        end

        raise TypeCheckErrorSet.new(@errors) if @errors.any?

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
          puts "!> #{constraint.repr}"
        end

        @errors << constraint
      end
    end
  end
end
