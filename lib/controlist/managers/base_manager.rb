module Controlist
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

        def enable_skip
          raise NotImplementedError
        end

        def disable_skip
          raise NotImplementedError
        end

      end

    end
  end
end
