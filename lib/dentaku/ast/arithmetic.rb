require 'bigdecimal'
require 'bigdecimal/util'
require_relative 'operation'

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
        v = BigDecimal(value, Float::DIG+1)
        v = v.to_i if prefer_integer && v.frac.zero?
        v
      end
    end

    class Addition < Arithmetic
      def operator
        :+
      end
    end

    class Subtraction < Arithmetic
      def operator
        :-
      end
    end

    class Multiplication < Arithmetic
      def operator
        :*
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
    end

    class Modulo < Arithmetic
      def operator
        :%
      end
    end

    class Exponentiation < Arithmetic
      def operator
        :**
      end
    end
  end
end
