module Controlist
  module Managers
    class ThreadBasedManager < BaseManager

      class << self

        def get_permission_package
          Thread.current[:permission_package]
        end

        def set_permission_package(package)
          Thread.current[:permission_package] = package
        end

        def skip?
          Thread.current[:skip_controlist] == true
        end

        def enable_skip
          Thread.current[:skip_controlist] = true
        end

        def disable_skip
          Thread.current[:skip_controlist] = nil
        end

      end

    end
  end
end

