module Controlist
  module Ext
    class RelationProxy

      METHODS = [:includes, :eager_load, :preload, :references, [:select, :_select!], :group, :order, :reorder, :unscope, :joins, :left_outer_joins, :where, :or, :having, :limit, :offset, :lock, :none, :readonly, :create_with, :from, :distinct, :extending, :reverse_order]

      def initialize(target)
        @target = target
      end

      METHODS.each do |old_method, new_method|
        new_method ||= old_method.to_s + "!"
        define_method old_method do |*args|
          @target.send new_method, *args
          self
        end
      end

      def method_missing(sym, *args)
        @target.send sym, *args
      end
    end
  end
end

