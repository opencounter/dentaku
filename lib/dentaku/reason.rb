module Dentaku
  class Reason < Variant
    variants(
      literal: [:ast],
      retval: [:ast],
      arg: [:ast, :index],
      operator: [:ast, :side],
      identifier: [:ast],
    )
  end
end
