module ActiveCortex::Adapter
  module ActiveRecord
    extend ActiveSupport::Concern
  
    class_methods do
    
      def self.extended(other)
        other.before_save     :activecortex_start
        other.before_destroy  :activecortex_start
        
        other.after_create  { activecortex_track(:create) }
        other.after_update  { activecortex_track(:update) }
        other.before_destroy { activecortex_track(:destroy) }
        
        other.after_commit  { activecortex_complete }
      end
      
      def inherited(subclass)
        super
        
        subclass.instance_variable_set('@activecortex', @activecortex.clone) if defined?(@activecortex)
      end
      
      def track(exclude: [], habtm_model: nil)
        @activecortex = {exclude: Array(exclude), habtm_model: habtm_model}
      end
      
      def has_and_belongs_to_many(name, scope = nil, options = {}, &extension)
        super
        habtm_model = self.const_get("HABTM_#{name.to_s.camelize}")
        
        habtm_model.track habtm_model: {
          :left_side => { foreign_key: "#{base_class.name.underscore}_id", inverse_of: name.to_s },
          name.to_s.singularize.to_sym => {inverse_of: self.name.underscore.pluralize.to_s}
        }
        
        callback = ->(method, owner, record) {
          owner.activecortex_association_udpated(
            record.class.reflect_on_association(owner.class.reflect_on_association(name.to_s).options[:inverse_of].to_s),
            owner.id,
            removed: [record.id],
            timestamp: owner.activecortex_timestamp
          )
          record.activecortex_association_udpated(
            owner.class.reflect_on_association(name.to_s),
            record.id,
            removed: [owner.id],
            timestamp: owner.activecortex_timestamp
          )
        }
        self.send("after_remove_for_#{name}=", Array(self.send("after_remove_for_#{name}")).compact + [callback])
      end
    end
    
    def activecortex_id
      "#{self.class.name}/#{id}"
    end
    
    def activecortex_timestamp
      @activecortex_timestamp ||= Time.now.utc
    end
    
    def activecortex_start
      if activecortex_tracking && !instance_variable_defined?(:@activecortex_finish)
        @activecortex_finish = !Thread.current[:activecortex_event]
      end
      @activecortex_timestamp = Time.now.utc
    end
    
    def activecortex_complete
      @activecortex_timestamp = nil
      if instance_variable_defined?(:@activecortex_finish) && @activecortex_finish && activecortex_tracking
        activecortex_event.save! if activecortex_event
        Thread.current[:activecortex_event] = nil
        @activecortex_timestamp = nil
      end
    end
    
    def activecortex_tracking
      if self.class.instance_variable_defined?(:@activecortex)
        self.class.instance_variable_get(:@activecortex)
      end
    end
    
    def activecortex_event
      case Thread.current[:activecortex_event]
      when ActiveCortex::Event
        Thread.current[:activecortex_event]
      when Hash
        Thread.current[:activecortex_event][:timestamp] ||= @activecortex_timestamp
        Thread.current[:activecortex_event] = ActiveCortex::Event.new(Thread.current[:activecortex_event])
      when Fixnum
      else
        Thread.current[:activecortex_event] = ActiveCortex::Event.new(timestamp: @activecortex_timestamp)
      end
    end
    
    def activecortex_track(type)
      return if !activecortex_tracking
      
      if type == :create || type == :update
        diff = self.changes.select { |k,v| !activecortex_tracking[:exclude].include?(k.to_sym) }
        if type == :create
          self.class.columns.each do |column|
            if !diff[column.name] && !activecortex_tracking[:exclude].include?(column.name.to_sym) && column.default != self.attributes[column.name]
              diff[column.name] = [nil, self.attributes[column.name]]
            end
          end
        end
      elsif type == :destroy
        diff = self.attributes.select { |k| !activecortex_tracking[:exclude].include?(k.to_sym) }.map { |k, i| [k, [i, nil]] }.to_h
      end
      
      return if type == :update && diff.size == 0
      
      if !activecortex_tracking[:habtm_model]
        activecortex_event.action!({
          type: type,
          subject: self.activecortex_id,
          diff: diff,
          timestamp: @activecortex_timestamp
        })
      end
      
      self._reflections.each do |key, reflection|
        foreign_key = activecortex_tracking.dig(:habtm_model, reflection.name, :foreign_key) || reflection.foreign_key

        if areflection = self.class.reflect_on_association(reflection.name)
          if areflection.macro == :has_and_belongs_to_many && type == :create
            self.send("#{areflection.name.to_s.singularize}_ids").each do |fid|
              next unless fid
              activecortex_association_udpated(areflection, fid, added: [diff['id'][1]], timestamp: activecortex_timestamp)
              activecortex_association_udpated(areflection.klass.reflect_on_association(areflection.options[:inverse_of]), diff['id'][1], added: [fid], timestamp: activecortex_timestamp, type: :create)
            end
          elsif areflection.macro == :has_and_belongs_to_many && type == :destroy
            self.send("#{areflection.name.to_s.singularize}_ids").each do |fid|
              activecortex_association_udpated(areflection, fid, removed: [diff['id'][0]], timestamp: activecortex_timestamp, type: :update)
              activecortex_association_udpated(areflection.klass.reflect_on_association(areflection.options[:inverse_of]), diff['id'][0], removed: [fid], timestamp: activecortex_timestamp, type: :update)
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
          activecortex_association_udpated(reflection, old_id, removed: [relation_id], timestamp: activecortex_timestamp) if old_id
          activecortex_association_udpated(reflection, new_id, added:   [relation_id], timestamp: activecortex_timestamp) if new_id
        end
        
      end
      
    end

    def activecortex_association_udpated(reflection, id, added: [], removed: [], timestamp: nil, type: :update)
      if inverse_of = activecortex_tracking.dig(:habtm_model, reflection.name, :inverse_of)
        inverse_of = reflection.klass.reflect_on_association(inverse_of)
      else
        inverse_of = reflection.inverse_of
      end

      if inverse_of.nil?
        puts "NO INVERSE for #{self.class}.#{reflection.name}!!!"
        return
      end
      
      model_name = reflection.klass.base_class.model_name.name
      
      action = activecortex_event.action_for("#{model_name}/#{id}") || activecortex_event.action!({
        type: type,
        subject: "#{model_name}/#{id}",
        timestamp: timestamp# || Time.now
      })
      
      action.diff ||= {}
      if inverse_of.collection? || activecortex_tracking[:habtm_model]
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