require_relative './operation'
require 'bigdecimal'
require 'bigdecimal/util'

module Dentaku
  module AST
    class Arithmetic < Operation
      def value
        l = cast(left.evaluate)
        r = cast(right.evaluate)
        l.public_send(operator, r)
      end

      def types
        [:numeric, :numeric, :numeric]
      end

      private

      def cast(value, prefer_integer=true)
        v = BigDecimal.new(value, Float::DIG+1)
        v = v.to_i if prefer_integer && v.frac.zero?
        v
      end
    end

    class Addition < Arithmetic
      def operator
        :+
      end

      def self.precedence
        10
      end

      def simplified_value
        literal, unliteral = children.partition(&:literal?)

        if literal.length == 2
          make_literal(value)
        elsif literal.length == 1 && literal.first.value == 0
          unliteral.first
        else
          self
        end
      end
    end

    class Subtraction < Arithmetic
      def operator
        :-
      end

      def self.precedence
        10
      end

      def simplified_value
        return make_literal(0) if left == right

        if children.all?(&:literal?)
          make_literal(value)
        elsif right.literal? && right.value == 0
          left
        elsif left.literal? && left.value == 0
          Negation.new(right)
        else
          self
        end
      end
    end

    class Multiplication < Arithmetic
      def operator
        :*
      end

      def self.precedence
        20
      end

      def simplified_value
        literal, unliteral = children.partition(&:literal?)

        case literal.length
        when 0 then self
        when 1 then
          case literal.first.value
          when 0 then make_literal(0)
          when 1 then unliteral.first
          else self
          end
        when 2 then make_literal(value)
        end
      end
    end

    class Division < Arithmetic
      def operator
        :/
      end

      def value
        r = cast(right.evaluate, false)
        raise ZeroDivisionError if r.zero?

        cast(cast(left.evaluate) / r)
      end

      def simplified_value
        return self unless right.literal?
        r = cast(right.value, false)

        if r == 0
          AST::ExceptionNode.new(ZeroDivisionError)
        elsif r == 1
          left
        elsif left.literal?
          make_literal(value)
        else
          self
        end
      end

      def self.precedence
        20
      end
    end

    class Modulo < Arithmetic
      def operator
        :%
      end

      def self.precedence
        20
      end
    end

    class Exponentiation < Arithmetic
      def operator
        :**
      end

      def self.precedence
        30
      end

      def simplified_value
        return self unless right.literal?
        r = cast(right.value, false)

        if r == 0
          make_literal(1)
        elsif r == 1
          left
        elsif left.literal?
          make_literal(value)
        else
          self
        end
      end
    end
  end
end
