module Dentaku
  class Reason < Variant
    variants(
      literal: [:ast],
      retval: [:ast],
      arg: [:ast, :index],
      operator: [:ast, :side],
      identifier: [:ast],
      dictionary_key: [:ast, :key],
      list_member: [:ast, :index],
    )
  end
end
