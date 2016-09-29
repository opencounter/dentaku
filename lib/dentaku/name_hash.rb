module Dentaku
  class NameHash < Hash
    def [](key)
      super(normalize_key(key))
    end

    def []=(key, val)
      super(normalize_key(key), val)
    end

    def merge!(other)
      other.each do |k, v|
        self[k] = v
      end

      self
    end

    def merge(other)
      dup.merge!(other)
    end

    def has_key?(k)
      super(normalize_key(k))
    end

    private
    def normalize_key(key)
      key.to_s.downcase
    end
  end
end
