class Metadatum

  attr_accessor :event_id, :key, :value

  def initialize(attrs)
    attrs.each { |k, v| self.send("#{k}=", v) }
  end

end
