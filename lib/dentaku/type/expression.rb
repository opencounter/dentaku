module Dentaku
  module Type
    class Expression < Variant
      variants(
        syntax: [:ast],
        param: [:name, :arguments],
        struct: [:keys, :types],
        variable: [:name, :uniq],
        var: [:name],
      )

      def self.concrete(name)
        param(name, [])
      end

      def self.uniq
        Thread.current[:dentaku_type_uniq_counter] ||= 0
        Thread.current[:dentaku_type_uniq_counter] += 1
      end

      def self.make_variable(name)
        variable(name, uniq)
      end

      def self.from_sexpr(sexpr)
        if sexpr.is_a?(String)
          Syntax.parse_type(sexpr)
        elsif sexpr.is_a?(Type)
          sexpr.to_expr
        else
          super
        end
      end

      def map(&blk)
        cases(
          param: ->(name, arguments) {
            Expression.param(name, arguments.map(&blk))
          },
          struct: ->(keys, types) {
            Expression.struct(keys, types.map(&blk))
          },
          other: self
        )
      end

      def self.make_param(name, arguments)
        decl = DECLARED_TYPES[name.to_sym]
        unless decl && decl.arity == arguments.size
          raise "undeclared param type :#{name}/#{arguments.size}"
        end

        param(name, arguments)
      end

      def resolve(reverse_scope={})
        cases(
          param: ->(name, arguments) {
            Type.declared(DECLARED_TYPES[name].new(arguments.map(&:resolve)))
          },
          variable: -> (name, uniq) {
            var_name = reverse_scope[[name, uniq]]
            next Type.abstract unless var_name
            Type.bound(var_name)
          },
          struct: -> (keys, types) {
            Type.struct(keys, types.map { |t| t.resolve(reverse_scope) })
          },
          other: ->() {
            Type.abstract
          }
        )
      end

      def resolve_vars(scope={})
        cases(
          var: ->(name) {
            scope[name] ||= Expression.variable(name, self.class.uniq)
          },
          other: -> { map { |x| x.resolve_vars(scope) } },
        )
      end

      def expression_hash
        cases(
          syntax: ->(ast) {
            ast.loc_range.repr + ast.repr
          },
          other: ->(*) { repr }
        )
      end

      def ==(other)
        self.expression_hash == other.expression_hash
      end

      def inspect
        "<Type::Expression #{repr}>"
      end

      def repr
        cases(
          syntax: ->(ast) { "(#{ast.repr})" },
          param: ->(name, arguments) {
            if arguments.empty?
              ":#{name}"
            elsif name == :list && arguments.size == 1
              "[#{arguments[0].repr}]"
            elsif name == :lambda && arguments.size >= 2
              arg_repr = arguments[1..].map(&:repr).join(' ')
              ":lambda(#{arg_repr} => #{arguments[0].repr})"
            else
              ":#{name}(#{arguments.map(&:repr).join(' ')})"
            end
          },
          variable: ->(name, uniq) { "%#{name}#{uniq}" },
          var: -> (name) { "%%#{name}" },
          struct: -> (keys, values) {
            "{#{keys.zip(values).map { |(k, v)| "#{k}: #{v.repr}" }.join(', ')}}"
          },
        )
      end

    end
  end
end
