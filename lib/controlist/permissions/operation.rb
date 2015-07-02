module Controlist
  module Permissions

    CREATE = :create
    READ = :read
    UPDATE = :update
    DELETE = :delete

    module_function

    def is_persistence?(operation)
      [CREATE, UPDATE, DELETE].include? operation.to_sym
    end

    def is_create?(operation)
      CREATE == operation.to_sym
    end

    def is_read?(operation)
      READ == operation.to_sym
    end

    def is_update?(operation)
      UPDATE == operation.to_sym
    end

    def is_delete?(operation)
      DELETE == operation.to_sym
    end

  end
end
