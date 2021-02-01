module Dentaku
  module Type
    class Error < StandardError
      def locations
        raise 'abstract'
        return []
      end

      def as_json
        {
          error_type: self.class.name.split(':').last,
          message: message,
          locations: locations,
          **additional_json
        }
      end

      def additional_json
        {}
      end
    end

    class UnboundIdentifier < Error
      attr_reader :identifier
      def initialize(ident, type_solution)
        @identifier = ident
        @solution = type_solution
      end

      def locations
        [@identifier.loc_range]
      end

      def unbound_type
        @solution.fetch(Expression.syntax(@identifier)) { Type.abstract }.resolve
      end

      def message
        "UnboundIdentifier `#{identifier.repr}' of type #{unbound_type.repr}"
      end

      def additional_json
        { identifier: identifier, expected_type: unbound_type }
      end
    end

    class TypeMismatch < Error
      attr_reader :constraint
      def initialize(constraint)
        @constraint = constraint
      end

      def locations
        @locations ||= extract_ranges(@constraint.ast_nodes)
      end

      def extract_ranges(causes)
        causes.map do |cause|
          case cause
          when Array then cause.flat_map(&method(:extract_ranges))
          when Token, AST::Node then cause.loc_range
          end
        end
      end

      def message
        "TypeMismatch #{@constraint.repr_with_reason}"
      end

      def additional_json
        { constraint: @constraint.to_sexpr }
      end
    end

    class ErrorSet < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
      end

      def message
        "Type errors:\n#{@errors.map(&:message).join("\n")}"
      end

      def inspect
        "#<#{self.class.name} #{@errors.map(&:message).join('; ')}>"
      end
    end
  end
end
