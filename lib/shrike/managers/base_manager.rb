module Shrike
  module Managers
    class BaseManager

      class << self

        def get_permission_package
          raise NotImplementedError
        end

        def set_permission_package(package)
          raise NotImplementedError
        end

        def skip?
          raise NotImplementedError
        end

        def open_skip
          raise NotImplementedError
        end

        def close_skip
          raise NotImplementedError
        end

      end

    end
  end
end
