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
    end

    class Subtraction < Arithmetic
      def operator
        :-
      end

      def self.precedence
        10
      end
    end

    class Multiplication < Arithmetic
      def operator
        :*
      end

      def self.precedence
        20
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
    end
  end
end
