class HerokuStack
  class << self
    attr_writer :name

    def name
      @name ||= default_name
    end

    def default_name
      'cedar'
    end
  end
end
