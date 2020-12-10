require_relative '../function'

module Dentaku
  module AST
    class Ifs < Function
      # This function (based off excel IFS function) was requested by Matt Cloyd 
      # https://support.microsoft.com/en-us/office/ifs-function-36329a26-37b2-467c-972b-4a39bd951d45
      #
      # Example
      # ifs(
      #   a > 1, 100,
      #   b > 100, 200,
      #   b < 100, 300,
      #   true, 0 # default case
      # )
      def self.type_syntax
        # We want something like
        # "ifs(*[:bool, %a]...) = %a"
        # but not sure if it's even reasonable to get our type system to handle something like an unending sequence of types (:bool, %a)
        #
        # we have other places where a tuple would be handy. a list that can support multiple types, but it's length and types are fixed
        # e.g [:bool, :numeric, :string]
        #
        # with a tuple this could be done like
        # ifs([[:bool, %a]]) = %a
        #
        # ifs([
        #   [a > 1, 100],
        #   [b > 100, 200],
        #   [b < 100, 300],
        #   [default, o],
        # ])
        #
        "ifs(:bool, %a) = %a"
      end

      def initialize(*args)
        if args.length.even?
          @lookup = Hash[*args]
        else
          raise "Uneven args"
        end
      end

      def value
        @lookup.each do |predicate, value|
          if predicate.evaluate
            return value.evaluate
          end
        end
      end

      def dependencies(context={})
        @lookup.to_a.flat_map { |e| e.dependencies(context) }
      end

      def generate_constraints(context)
        # TODO
      end
    end
  end
end

Dentaku::AST::Function.register_class(Dentaku::AST::Ifs)
