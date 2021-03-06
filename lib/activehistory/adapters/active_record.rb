module ActiveHistory::Adapter
  module ActiveRecord
    extend ActiveSupport::Concern

    class_methods do
    
      def self.extended(other)
        other.after_create      { activehistory_track(:create) }
        other.after_update      { activehistory_track(:update) }
        other.before_destroy    { activehistory_track(:destroy) }
      end
      
      def inherited(subclass)
        super
        subclass.instance_variable_set('@activehistory', @activehistory.clone) if defined?(@activehistory)
      end
      
      def track(track_model = true, exclude: [], habtm_model: nil)
        if track_model == false
          @activehistory = nil
        else
          options = { exclude: Array(exclude) }
          options[:habtm_model] = habtm_model if habtm_model
          @activehistory = options
        end
      end
      
      def has_and_belongs_to_many(name, scope = nil, **options, &extension)
        super
        name = name.to_s
        habtm_model = self.const_get("HABTM_#{name.to_s.camelize}")

        foreign_key = options[:foreign_key] || "#{base_class.name.underscore}_id"
        association_foreign_key = options[:association_foreign_key]
        association_foreign_key ||= "#{options[:class_name].underscore}_id" if options[:class_name]
        association_foreign_key ||= "#{name.singularize.underscore}_id"
        inverse_of = (options[:inverse_of] || self.name.underscore.pluralize).to_s
        
        habtm_model.track habtm_model: {
          :left_side => { foreign_key: foreign_key, inverse_of: name.to_s },
          name.to_s.singularize.to_sym => {
            foreign_key: association_foreign_key,
            inverse_of: inverse_of
          }
        }

        callback = ->(method, owner, record) {
          owner.activehistory_association_changed(name, removed: [record.id])
        }
        self.send("after_remove_for_#{name}=", Array(self.send("after_remove_for_#{name}")).compact + [callback])
      end
      
      def activehistory_association_changed(id, reflection_or_relation_name, added: [], removed: [], timestamp: nil, type: :update, propagate: true)
        return if removed.empty? && added.empty?
        reflection = if reflection_or_relation_name.is_a?(String) || reflection_or_relation_name.is_a?(Symbol)
          reflect_on_association(reflection_or_relation_name)
        else
          reflection_or_relation_name
        end
        
        action = ActiveHistory.current_event(timestamp: timestamp).action_for(self, id, { type: type, timestamp: timestamp })

        if reflection
          if reflection.collection?
            diff_key = "#{reflection.name.to_s.singularize}_ids"

            action.diff[diff_key] ||= [[], []]
            action.diff[diff_key][0] |= removed
            action.diff[diff_key][1] |= added

            in_common = (action.diff[diff_key][0] & action.diff[diff_key][1])
            if !in_common.empty?
              action.diff[diff_key][0] = action.diff[diff_key][0] - in_common
              action.diff[diff_key][1] = action.diff[diff_key][1] - in_common
            end
          else
            diff_key = "#{reflection.name.to_s.singularize}_id"
            if action.diff.has_key?(diff_key) && action.diff[diff_key][0] == added.first
              action.diff.delete(diff_key)
            else
              action.diff[diff_key] ||= [removed.first, added.first]
            end
          end
      
          if propagate && inverse_reflection = reflection.inverse_of
            inverse_klass = inverse_reflection.active_record

            added.each do |added_id|
              inverse_klass.activehistory_association_changed(added_id, inverse_reflection,
                added: [id],
                timestamp: timestamp,
                type: type,
                propagate: false
              )
            end
        
            removed.each do |removed_id|
              inverse_klass.activehistory_association_changed(removed_id, inverse_reflection,
                removed: [id],
                timestamp: timestamp,
                type: type,
                propagate: false
              )
            end
          end
        end
      end
      
    end

    def activehistory_timestamp
      @activehistory_timestamp ||= Time.now.utc
    end
    
    def with_transaction_returning_status
      @activehistory_timestamp = Time.now.utc
      if !Thread.current[:activehistory_save_lock]
        run_save = true
        Thread.current[:activehistory_save_lock] = true
        if !Thread.current[:activehistory_event]
          destroy_current_event = true
          Thread.current[:activehistory_event] = ActiveHistory::Event.new(timestamp: @activehistory_timestamp)
        end
      end

      status = nil
      self.class.transaction do
        unless has_transactional_callbacks?
          sync_with_transaction_state if @transaction_state&.finalized?
          @transaction_state = self.class.connection.current_transaction.state
        end
        remember_transaction_record_state

        status = yield
        if status
          if run_save && ActiveHistory.configured? && !activehistory_event.actions.empty?
            activehistory_event&.save!
          end
        else
          raise ::ActiveRecord::Rollback
        end
        status
      ensure
        @activehistory_timestamp = nil
        if run_save
          Thread.current[:activehistory_save_lock] = false
        end
        if destroy_current_event
          Thread.current[:activehistory_event] = nil
        end

        if has_transactional_callbacks? &&
            (@_new_record_before_last_commit && !new_record? || _trigger_update_callback || _trigger_destroy_callback)
          add_to_transaction
        end
      end
    end

    def activehistory_tracking
      if ActiveHistory.configured? && self.class.instance_variable_defined?(:@activehistory)
        self.class.instance_variable_get(:@activehistory)
      end
    end
    
    def activehistory_event
      ActiveHistory.current_event(timestamp: activehistory_timestamp)
    end
    
    def activehistory_track(type)
      return if !activehistory_tracking

      if type == :create || type == :update
        diff = self.saved_changes.select { |k,v| !activehistory_tracking[:exclude].include?(k.to_sym) }

        if type == :create
          self.class.columns.each do |column|
            if !diff[column.name] && !activehistory_tracking[:exclude].include?(column.name.to_sym) && column.default != self.attributes[column.name]
              diff[column.name] = [nil, self.attributes[column.name]]
            end
          end
        end
      elsif type == :destroy
        relations_ids = self.class.reflect_on_all_associations.map { |r| "#{r.name.to_s.singularize}_ids" }

        diff = self.attributes.select do |k|
          !activehistory_tracking[:exclude].include?(k.to_sym) 
        end.map do |k, i|
          if relations_ids.include?(k)
            [ k, [ i, [] ] ]
          else
            [ k, [ i, nil ] ]
          end
        end.to_h
      end

      if type == :update
        diff_without_timestamps = if self.class.record_timestamps
          diff.keys - (self.class.send(:timestamp_attributes_for_update_in_model) + self.class.send(:timestamp_attributes_for_create_in_model))
        else
          diff.keys
        end
        
        return if diff_without_timestamps.empty?
      end

      if activehistory_tracking[:habtm_model]
        if type == :create
          left_side = self.class.reflect_on_association(:left_side)
          left_side_id_name = activehistory_tracking[:habtm_model][:left_side][:foreign_key]
          left_side_id = self.send(left_side_id_name)
          right_side_name = activehistory_tracking[:habtm_model].keys.find { |x| x != :left_side }
          right_side = self.class.reflect_on_association(right_side_name)
          right_side_id_name = activehistory_tracking[:habtm_model][right_side_name][:foreign_key]
          right_side_id = self.send(right_side_id_name)

          left_side.klass.activehistory_association_changed(
            left_side_id,
            activehistory_tracking[:habtm_model][:left_side][:inverse_of],
            added: [right_side_id],
            timestamp: activehistory_timestamp,
            propagate: false
          )

          right_side.klass.activehistory_association_changed(
            right_side_id,
            activehistory_tracking[:habtm_model][right_side_name][:inverse_of],
            added: [left_side_id],
            timestamp: activehistory_timestamp,
            propagate: false
          )
        end
      else
        activehistory_event.action_for(self.class, id, {
          type: type,
          diff: diff,
          timestamp: activehistory_timestamp
        })
        
        
        self.class.reflect_on_all_associations.each do |reflection|
          next if activehistory_tracking[:habtm_model]
          
          if reflection.macro == :has_and_belongs_to_many && type == :destroy
            activehistory_association_changed(reflection, removed: self.send("#{reflection.name.to_s.singularize}_ids"))
          elsif reflection.macro == :belongs_to && diff.has_key?(reflection.foreign_key)
            case type
            when :create
              old_id = nil
              new_id = diff[reflection.foreign_key][1]
            when :destroy
              old_id = diff[reflection.foreign_key][0]
              new_id = nil
            else
              old_id = diff[reflection.foreign_key][0]
              new_id = diff[reflection.foreign_key][1]
            end
            
            relation_id = self.id || diff.find { |k, v| k != foreign_key }[1][1]
            
            if reflection.polymorphic?
            else
              activehistory_association_changed(reflection, removed: [old_id]) if old_id
              activehistory_association_changed(reflection, added:   [new_id]) if new_id
            end
            
          end
        end
      end

      
    end

    def activehistory_association_changed(relation_name, added: [], removed: [], timestamp: nil, type: :update)
      timestamp ||= activehistory_timestamp
      
      self.class.activehistory_association_changed(id, relation_name,
        added: added,
        removed: removed,
        timestamp: timestamp,
        type: type
      )
    end
    
    def activehistory_association_udpated(reflection, id, added: [], removed: [], timestamp: nil, type: :update)
      return if !activehistory_tracking || (removed.empty? && added.empty?)
      klass = reflection.active_record
      inverse_klass = reflection.klass
      
      inverse_association = if activehistory_tracking.has_key?(:habtm_model)
        inverse_klass.reflect_on_association(activehistory_tracking.dig(:habtm_model, reflection.name.to_s.singularize.to_sym, :inverse_of))
      else
        reflection.inverse_of
      end

      if inverse_association.nil?
        puts "NO INVERSE for #{self.class}.#{reflection.name}!!!"
        return
      end
      
      action = activehistory_event.action_for(klass, id, {
        type: type,
        timestamp: timestamp
      })
      
      action.diff ||= {}
      if (reflection.collection? || activehistory_tracking[:habtm_model])
        diff_key = "#{reflection.name.to_s.singularize}_ids"
        action.diff[diff_key] ||= [[], []]
        action.diff[diff_key][0] |= removed
        action.diff[diff_key][1] |= added
      else
        diff_key = "#{reflection.name.to_s.singularize}_id"
        action.diff[diff_key] ||= [removed.first, added.first]
      end
      
      removed.each do |removed_id|
        action = activehistory_event.action_for(inverse_klass, removed_id, {
          type: type,
          timestamp: timestamp
        })
      
        action.diff ||= {}

        if inverse_association.collection? || activehistory_tracking[:habtm_model]
          diff_key = "#{inverse_association.name.to_s.singularize}_ids"
          action.diff[diff_key] ||= [[], []]
          action.diff[diff_key][0] |= [id]
        else
          diff_key = "#{inverse_association.name.to_s.singularize}_id"
          action.diff[diff_key] ||= [id, nil]
        end
      end
      
      added.each do |added_id|
        action = activehistory_event.action_for(inverse_klass, added_id, {
          type: type,
          timestamp: timestamp
        })
      
        action.diff ||= {}
        if inverse_association.collection? || activehistory_tracking[:habtm_model]
          diff_key = "#{inverse_association.name.to_s.singularize}_ids"
          action.diff[diff_key] ||= [[], []]
          action.diff[diff_key][1] |= [id]
        else
          diff_key = "#{inverse_association.name.to_s.singularize}_id"
          action.diff[diff_key] ||= [nil, id]
        end
      end
    end

  end
end


module ActiveRecord
  module Associations
    class CollectionAssociation
      
      def delete_all(dependent = nil)
        activehistory_encapsulate do
          if dependent && ![:nullify, :delete_all].include?(dependent)
            raise ArgumentError, "Valid values are :nullify or :delete_all"
          end

          dependent = if dependent
                        dependent
                      elsif options[:dependent] == :destroy
                        :delete_all
                      else
                        options[:dependent]
                      end

          if dependent == :delete_all

          elsif !owner.id.nil?
            removed_ids = self.scope.pluck(:id)
          
            action = owner.activehistory_event.action_for(self.reflection.active_record, owner.id, {
              type: :update,
              timestamp: owner.activehistory_timestamp
            })
            
            diff_key = "#{self.reflection.name.to_s.singularize}_ids"
            action.diff ||= {}
            action.diff[diff_key] ||= [[], []]
            action.diff[diff_key][0] |= removed_ids
          
            ainverse_of = self.klass.reflect_on_association(self.options[:inverse_of])
            if ainverse_of
              removed_ids.each do |removed_id|
                action = owner.activehistory_event.action_for(ainverse_of.active_record, removed_id, {
                  type: :update,
                  timestamp: owner.activehistory_timestamp
                })
                action.diff ||= {}
                if ainverse_of.collection?
                  diff_key = "#{ainverse_of.name.to_s.singularize}_ids"
                  action.diff[diff_key] ||= [[], []]
                  action.diff[diff_key][0] |= [owner.id]
                else
                  diff_key = "#{ainverse_of.name}_id"
                  action.diff[diff_key] ||= [owner.id, nil]
                end
              end
            end
          end

          delete_or_nullify_all_records(dependent).tap do
            reset
            loaded!
          end
        end
      end
      
      private
      
      def replace_records(new_target, original_target)
        activehistory_encapsulate do
          removed_records = target - new_target
          added_records = new_target - target
        
          delete(difference(target, new_target))

          unless concat(difference(new_target, target))
            @target = original_target
            raise RecordNotSaved, "Failed to replace #{reflection.name} because one or more of the " \
                                  "new records could not be saved."
          end

          if !owner.new_record?
            owner.activehistory_association_changed(self.reflection, added: added_records.map(&:id), removed: removed_records.map(&:id))
          end
        end
        
        target
      end
      
      def delete_or_destroy(records, method)
        activehistory_encapsulate do
          records = find(records) if records.any? { |record| record.kind_of?(Integer) || record.kind_of?(String) }
          records = records.flatten
          records.each { |record| raise_on_type_mismatch!(record) }
          existing_records = records.reject(&:new_record?)

          if existing_records.empty?
            remove_records(existing_records, records, method)
          else
            transaction { remove_records(existing_records, records, method) }
          end
        end
      end
      
      def activehistory_encapsulate
        @activehistory_timestamp = Time.now.utc

        if !Thread.current[:activehistory_save_lock]
          run_save = true
          Thread.current[:activehistory_save_lock] = true
          if Thread.current[:activehistory_event].nil?
            destroy_current_event = true
            Thread.current[:activehistory_event] = ActiveHistory::Event.new(timestamp: @activehistory_timestamp)
          end
        end
      
        result = yield

        if run_save && ActiveHistory.configured?  && !owner.activehistory_event.actions.empty?
          owner.activehistory_event&.save!
        end

        result
      ensure
        @activehistory_timestamp = nil
        if run_save
          Thread.current[:activehistory_save_lock] = false
        end
        if destroy_current_event
          Thread.current[:activehistory_event] = nil
        end
      end
      
    end
  end
end
