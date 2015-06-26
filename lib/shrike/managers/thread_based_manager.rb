module Shrike
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
          Thread.current[:skip_shrike] == true
        end

        def open_skip
          Thread.current[:skip_shrike] = true
        end

        def close_skip
          Thread.current[:skip_shrike] = nil
        end

      end

    end
  end
end

