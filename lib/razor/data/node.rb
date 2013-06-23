module Razor::Data
  class Node < Sequel::Model
    plugin :serialization, :json, :facts
    plugin :serialization, :json, :log

    many_to_one :policy

    def tags
      Tag.match(self)
    end

    def log_append(hash)
      self.log ||= []
      hash[:timestamp] ||= Time.now.to_i
      hash[:severity] ||= 'info'
      self.log << hash
    end

    # This is a hack around the fact that the auto_validates plugin does
    # not play nice with the JSON serialization plugin (the serializaton
    # happens in the before_save hook, which runs after validation)
    #
    # To avoid spurious error messages, we tell the validation machinery to
    # expect a Hash resp. an Array
    # FIXME: Figure out a way to address this issue upstream
    def schema_type_class(k)
      if k == :facts
        Hash
      elsif k == :log
        Array
      else
        super
      end
    end

    def self.checkin(hw_id, body)
      if node = lookup(hw_id)
        if body['facts'] != node.facts
          node.facts = body['facts']
          node.save
        end
      else
        node = create(:hw_id => hw_id, :facts => body['facts'])
      end
      Policy.bind(node) unless node.policy
      if node.policy
        # FIXME: Bound to a policy, what do we do next ?
      end
      { :action => :none }
    end

    def self.lookup(hw_id)
      self[:hw_id => hw_id]
    end
  end
end
