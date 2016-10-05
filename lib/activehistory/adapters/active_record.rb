module ActiveHistory::Adapter
  module ActiveRecord
    extend ActiveSupport::Concern
  
    class_methods do
    
      def self.extended(other)
        other.before_save     :activehistory_start
        other.before_destroy  :activehistory_start
        
        other.after_create  { activehistory_track(:create) }
        other.after_update  { activehistory_track(:update) }
        other.before_destroy { activehistory_track(:destroy) }
        
        other.after_commit  { activehistory_complete }
      end
      
      def inherited(subclass)
        super
        
        subclass.instance_variable_set('@activehistory', @activehistory.clone) if defined?(@activehistory)
      end
      
      def track(exclude: [], habtm_model: nil)
        @activehistory = {exclude: Array(exclude), habtm_model: habtm_model}
      end
      
      def has_and_belongs_to_many(name, scope = nil, options = {}, &extension)
        super
        habtm_model = self.const_get("HABTM_#{name.to_s.camelize}")
        
        habtm_model.track habtm_model: {
          :left_side => { foreign_key: "#{base_class.name.underscore}_id", inverse_of: name.to_s },
          name.to_s.singularize.to_sym => {inverse_of: self.name.underscore.pluralize.to_s}
        }
        
        callback = ->(method, owner, record) {
          owner.activehistory_association_udpated(
            record.class.reflect_on_association(owner.class.reflect_on_association(name.to_s).options[:inverse_of].to_s),
            owner.id,
            removed: [record.id],
            timestamp: owner.activehistory_timestamp
          )
          record.activehistory_association_udpated(
            owner.class.reflect_on_association(name.to_s),
            record.id,
            removed: [owner.id],
            timestamp: owner.activehistory_timestamp
          )
        }
        self.send("after_remove_for_#{name}=", Array(self.send("after_remove_for_#{name}")).compact + [callback])
      end
    end
    
    def activehistory_id
      "#{self.class.name}/#{id}"
    end
    
    def activehistory_timestamp
      @activehistory_timestamp ||= Time.now.utc
    end
    
    def activehistory_start
      if activehistory_tracking && !instance_variable_defined?(:@activehistory_finish)
        @activehistory_finish = !Thread.current[:activehistory_event]
      end
      @activehistory_timestamp = Time.now.utc
    end
    
    def activehistory_complete
      @activehistory_timestamp = nil
      if instance_variable_defined?(:@activehistory_finish) && @activehistory_finish && activehistory_tracking
        activehistory_event.save! if activehistory_event
        Thread.current[:activehistory_event] = nil
        @activehistory_timestamp = nil
      end
    end
    
    def activehistory_tracking
      if ActiveHistory.configured? && self.class.instance_variable_defined?(:@activehistory)
        self.class.instance_variable_get(:@activehistory)
      end
    end
    
    def activehistory_event
      case Thread.current[:activehistory_event]
      when ActiveHistory::Event
        Thread.current[:activehistory_event]
      when Hash
        Thread.current[:activehistory_event][:timestamp] ||= @activehistory_timestamp
        Thread.current[:activehistory_event] = ActiveHistory::Event.new(Thread.current[:activehistory_event])
      when Fixnum
      else
        Thread.current[:activehistory_event] = ActiveHistory::Event.new(timestamp: @activehistory_timestamp)
      end
    end
    
    def activehistory_track(type)
      return if !activehistory_tracking
      
      if type == :create || type == :update
        diff = self.changes.select { |k,v| !activehistory_tracking[:exclude].include?(k.to_sym) }
        if type == :create
          self.class.columns.each do |column|
            if !diff[column.name] && !activehistory_tracking[:exclude].include?(column.name.to_sym) && column.default != self.attributes[column.name]
              diff[column.name] = [nil, self.attributes[column.name]]
            end
          end
        end
      elsif type == :destroy
        diff = self.attributes.select { |k| !activehistory_tracking[:exclude].include?(k.to_sym) }.map { |k, i| [k, [i, nil]] }.to_h
      end
      
      return if type == :update && diff.size == 0
      
      if !activehistory_tracking[:habtm_model]
        activehistory_event.action!({
          type: type,
          subject: self.activehistory_id,
          diff: diff,
          timestamp: @activehistory_timestamp
        })
      end
      
      self._reflections.each do |key, reflection|
        foreign_key = activehistory_tracking.dig(:habtm_model, reflection.name, :foreign_key) || reflection.foreign_key

        if areflection = self.class.reflect_on_association(reflection.name)
          if areflection.macro == :has_and_belongs_to_many && type == :create
            self.send("#{areflection.name.to_s.singularize}_ids").each do |fid|
              next unless fid
              activehistory_association_udpated(areflection, fid, added: [diff['id'][1]], timestamp: activehistory_timestamp)
              activehistory_association_udpated(areflection.klass.reflect_on_association(areflection.options[:inverse_of]), diff['id'][1], added: [fid], timestamp: activehistory_timestamp, type: :create)
            end
          elsif areflection.macro == :has_and_belongs_to_many && type == :destroy
            self.send("#{areflection.name.to_s.singularize}_ids").each do |fid|
              activehistory_association_udpated(areflection, fid, removed: [diff['id'][0]], timestamp: activehistory_timestamp, type: :update)
              activehistory_association_udpated(areflection.klass.reflect_on_association(areflection.options[:inverse_of]), diff['id'][0], removed: [fid], timestamp: activehistory_timestamp, type: :update)
            end
          end
        end
        
        next unless reflection.macro == :belongs_to && (type == :destroy || diff.has_key?(foreign_key))
        
        case type
        when :create
          old_id = nil
          new_id = diff[foreign_key][1]
        when :destroy
          old_id = diff[foreign_key][0]
          new_id = nil
        else
          old_id = diff[foreign_key][0]
          new_id = diff[foreign_key][1]
        end
        
        relation_id = self.id || diff.find { |k, v| k != foreign_key }[1][1]
        
        if reflection.polymorphic?
        else
          activehistory_association_udpated(reflection, old_id, removed: [relation_id], timestamp: activehistory_timestamp) if old_id
          activehistory_association_udpated(reflection, new_id, added:   [relation_id], timestamp: activehistory_timestamp) if new_id
        end
        
      end
      
    end

    def activehistory_association_udpated(reflection, id, added: [], removed: [], timestamp: nil, type: :update)
      if inverse_of = activehistory_tracking.dig(:habtm_model, reflection.name, :inverse_of)
        inverse_of = reflection.klass.reflect_on_association(inverse_of)
      else
        inverse_of = reflection.inverse_of
      end

      if inverse_of.nil?
        puts "NO INVERSE for #{self.class}.#{reflection.name}!!!"
        return
      end
      
      model_name = reflection.klass.base_class.model_name.name
      
      action = activehistory_event.action_for("#{model_name}/#{id}") || activehistory_event.action!({
        type: type,
        subject: "#{model_name}/#{id}",
        timestamp: timestamp# || Time.now
      })
      
      action.diff ||= {}
      if inverse_of.collection? || activehistory_tracking[:habtm_model]
        diff_key = "#{inverse_of.name.to_s.singularize}_ids"
        action.diff[diff_key] ||= [[], []]
        action.diff[diff_key][0] |= removed
        action.diff[diff_key][1] |= added
      else
        diff_key = "#{inverse_of.name.to_s.singularize}_id"
        action.diff[diff_key] ||= [removed.first, added.first]
      end
    end

  end
end