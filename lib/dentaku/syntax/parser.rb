module Dentaku
  module Syntax
    module Parser
      extend self
      extend Matcher::DSL

      def parse(skel)
        if skel.root?
          parse_elems(skel.elems)
        else
          parse_elems([skel])
        end
      end

    protected

      # parse an array of skeleton nodes into a real AST
      # elems : [Syntax::Skeleton]
      # see skeleton.rb for the skeleton syntax
      #
      # HOW TO USE THE MATCHING DSL
      # (see matcher.rb for the implementation)
      #
      # match(nodes, matcher, &block_if_matched)
      #
      # will call the block only if the given nodes match the pattern. it will
      # split out certain captured elements (marked with ~) and provide those
      # as arguments to the block.
      #
      # types of patterns are:
      #
      # token(:my_cool_token)  - matches a single-token node of the given type
      # nested(:my_open_token) - matches a nested node opened by a token of
      #                          the given type
      # _ OR ignore            - matches anything at all
      # __ OR nonempty         - matches anything at all, provided there is at least
      #                          one node to match
      # exactly(a, b, c, ...)  - matches a sequence of nodes that each individually
      #                          match the given patterns, with no extra nodes
      #                          hanging around
      #
      # lsplit(split, before, after) - matches a sequence of tokens that can be
      #                                split by the leftmost match of `split`,
      #                                and will additionally match `before` and
      #                                `after` patterns to whatever comes before
      #                                and after the split node. note that the
      #                                split node can only be one node, so this
      #                                won't work with exactly(...) or similar.
      #
      # rsplit(split, before, after) - same as lsplit but searches from the right
      #
      # starts(token, after)   - matches a sequence of tokens that begins with the
      #                          given start token, and matches a pattern against
      #                          the rest of the sequence
      #
      # ends(prefix, last)     - same as starts(...) but matches the last token
      #
      # capture(matcher)
      # OR
      # ~matcher               - matches a node or sequence against the matcher
      #                          but captures the value to be passed into a
      #                          block argument
      #
      # NOTE: this is still very much a manual parser! The matching DSL is just
      # a way of factoring out what would otherwise be a lot of tedious if/else
      # and data structure unpacking. It's helpful to read each `match` statement
      # as a fancy `if`. In fact, `match` itself will return a boolean to indicate
      # whether it has matched, which is used here in `parse_comma_sep`.
      def parse_elems(elems)

        # first: detect errors from the tokenizer or skeleton parser layers
        # and split them apart
        match elems, rsplit(~error, ~_, ~_) do |err, before, after|
          # [jneen] this could also be a valid way of doing it, but i feel like we'd
          # end up with a lot of useless error messages

          # return invalid(err, err.message, parse_elems(before), parse_elems(after))
          return invalid(err, err.message)
        end

        # loosest precedence: AND / OR. note the `rsplit` - rightmost operators
        # should be on the outside.
        match elems, rsplit(~token(:combinator), ~__, ~__) do |op, before, after|
          lhs = parse_elems(before)
          rhs = parse_elems(after)

          class_ = op.value == :and ? :And : :Or

          return ast class_, elems, lhs, rhs
        end

        # next precedence: comparator ops: < > = != etc
        match elems, lsplit(~token(:comparator), ~__, ~__) do |op, before, after|
          lhs = parse_elems(before)
          rhs = parse_elems(after)

          op_class = case op.value
          when :<= then :LessThanOrEqual
          when :>= then :GreaterThanOrEqual
          when :< then :LessThan
          when :> then :GreaterThan
          when :!=, :'<>' then :NotEqual
          when :==, :'=' then :Equal
          else return invalid op, 'unknown comparison operator', lhs, rhs
          end

          return ast op_class, elems, lhs, rhs
        end

        # next precedence: range expressions A..B
        match elems, lsplit(token(:range), ~__, ~__) do |before, after|
          lhs = parse_elems(before)
          rhs = parse_elems(after)

          return ast :Range, elems, lhs, rhs
        end

        # next precedence: additive expressions A + B, A - B
        match elems, rsplit(~token(:additive), ~__, ~__) do |op, before, after|
          lhs = parse_elems(before)
          rhs = parse_elems(after)

          return case op.value
          when '-' then ast :Subtraction, elems, lhs, rhs
          when '+' then ast :Addition, elems, lhs, rhs
          else invalid op, 'unknown additive operation', lhs, rhs
          end
        end

        # next precedence: negation
        match elems, starts(token(:minus), ~__) do |exp|
          return ast :Negation, exp, parse_elems(exp)
        end

        # next precedence: multiplicative expressions A * B, A / B, A % B
        match elems, rsplit(~token(:multiplicative), ~__, ~__) do |op, before, after|
          lhs = parse_elems(before)
          rhs = parse_elems(after)

          return case op.value
          when '*' then ast :Multiplication, elems, lhs, rhs
          when '/' then ast :Division, elems, lhs, rhs
          when '%' then ast :Modulo, elems, lhs, rhs
          else invalid op, 'unknown multiplicative operation', lhs, rhs
          end
        end

        # next precedence: exponential expressions A ** B, A ^ B
        match elems, lsplit(~token(:exponential), ~__, ~__) do |op, before, after|
          lhs = parse_elems(before)
          rhs = parse_elems(after)

          return ast :Exponentiation, elems, lhs, rhs
        end

        # next precedence: function calls
        match elems, exactly(~token(:identifier), ~nested(:lparen)) do |func, args|
          fn = AST::Function.get(func.value, func)
          arg_nodes = parse_comma_sep(args.elems)
          fn_node = fn.new(*arg_nodes)
          fn_node.skeletons = elems
          return fn_node
        end

        # final precedence: "singleton" expressions (entirely contained within
        # one nested skeleton node). These all use the `exactly(...)` matcher
        # to make sure these are singletons.
        match elems, exactly(~nested(:case)) do |case_node|
          return parse_case(case_node)
        end

        match elems, exactly(~nested(:lbrack)) do |arr|
          return ast :List, arr, *parse_comma_sep(arr.elems)
        end

        match elems, exactly(~nested(:lbrace)) do |struct|
          return parse_struct(struct)
        end

        match elems, exactly(~nested(:lparen)) do |exp|
          return parse_elems(exp.elems)
        end

        match elems, exactly(~token(:identifier)) do |ident|
          return ast :Identifier, elems, ident.value
        end

        match elems, exactly(~token(:string)) do |str|
          return ast :String, str, str.value
        end

        match elems, exactly(~token(:numeric)) do |num|
          return ast :Numeric, num, num.value
        end

        match elems, exactly(~token(:logical)) do |log|
          return ast :Logical, log, log.value
        end

        invalid elems, "unrecognized syntax"
      end

      def parse_struct(struct)
        return ast :Struct, struct if struct.elems.empty?

        pairs = parse_comma_sep(struct.elems) do |segment|
          next ['_', invalid(struct, 'empty struct segment')] if segment.empty?
          key, *rest = segment
          next [key.repr, invalid(key, 'invalid key')] unless key.token?(:key)

          [key.value, parse_elems(rest)]
        end

        ast :Struct, struct, *pairs
      end

      # parse a comma separated list
      def parse_comma_sep(args, &b)
        b ||= method(:parse_elems)

        out = []

        # lsplit on comma until it doesn't match anymore
        loop do
          match args, lsplit(token(:comma), ~nonempty, ~_) do |before, after|
            out << b.call(before)
            args = after
          end or break
        end

        # if there is anymore, parse it out and add it on. otherwise,
        # it's a trailing comma, so we ignore it.
        out << b.call(args) if args.any?

        out
      end

      # there's a lot in this method but it's all fairly fundamental features
      # of CASE. we're receiving one skeleton node that neatly wraps up the
      # CASE...END grouping, but has everything else pretty much in a grab bag
      # inside. so we have to find the WHEN/THEN/ELSE tokens and group them
      # here
      def parse_case(case_node)
        # separate into arrays of clauses, such that the WHEN/THEN/ELSE token
        # is at the front of the array.
        # e.g. [[ {token :when} {token :logical("true")} ],
        #       [ {token :then} ... ],
        #       [ {token :else} ... ]]
        #
        # See Syntax::Token#clause, which returns true if the token is
        # one of when, then, else.
        #
        # Note this puts anything before the first clause in the first element -
        # this is conveniently the "head" or the inspected value
        clauses = [[]]
        case_node.elems.each do |elem|
          clauses << [] if elem.clause?
          clauses.last << elem
        end

        # head is possibly empty, for CASE WHEN ... THEN ... END
        # all other clauses guaranteed nonempty
        head = clauses.shift
        head = head.empty? ? nil : parse_elems(head)
        rest = clauses.map { |h, *r| [h, parse_elems(r)] }

        # for generating invalid nodes in case of error
        children = [head, *rest.map(&:last)].compact

        # once head is popped, there should be an even number of clauses, except
        # possibly for the singular ELSE clause at the end
        last = (rest.pop if clauses.size.odd?)

        # i don't think there's a use case for CASE ELSE ... END but hey it'd
        # technically work. disallowing it here tho
        return invalid case_node, 'a CASE statement must have at least one clause', *children if clauses.empty?

        # `rest` is even-sized now, so let's group them in pairs that *should*
        # be when/then
        pairs = make_pairs(rest)

        # make sure each pair is *actuall* when followed by then, and only
        # grab the resulting AST
        pairs.map! do |(w, t)|
          when_tok, when_exp = w
          unless when_tok.token?(:when)
            when_exp = invalid(when_tok, 'expected a WHEN clause', when_exp)
          end

          then_tok, then_exp = t
          unless then_tok.token?(:then)
            then_exp = invalid(then_tok, 'expected a THEN clause', then_exp)
          end

          [when_exp, then_exp]
        end

        # if there was an odd clause at the end, make sure it's an ELSE
        else_exp = nil
        if last
          else_tok, else_exp = last
          unless else_tok.token?(:else)
            else_exp = invalid else_tok, "hanging #{else_tok.tok.category.to_s.upcase} clause", else_exp
          end
        end

        ast :Case, case_node, head, pairs, else_exp
      end

      # in_groups_of(2), but without rails
      # [a, b, c, d, e, f] => [[a, b], [c, d], [e, f]]
      def make_pairs(arr)
        out = []
        arr.each_with_index do |e, i|
          out << [] if i.even?
          out.last << e
        end

        out
      end

      def ast(name, node, *args)
        node = [node] unless node.is_a?(Array)
        AST.const_get(name).new(*args).tap { |n| n.skeletons = node }
      end

      def invalid(node, message, *children)
        ast :Invalid, node, message, *children
      end
    end
  end
end
