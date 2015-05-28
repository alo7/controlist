module Shrike
  class Sample

    attr_accessor :name

    def fancy_name
      ">> " + self.name
    end

  end
end
