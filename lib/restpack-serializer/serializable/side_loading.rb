module RestPack::Serializer::SideLoading
  extend ActiveSupport::Concern

  module ClassMethods
    def side_loads(models, options)
      side_loads = {}
      return side_loads if models.empty? || options.includes.nil?

      options.includes.each do |include|
        side_loads.merge! side_load(include, models, options)
      end
      side_loads
    end

    def filterable_by
      filters = [self.model_class.primary_key.to_sym]
      filters += self.model_class.reflect_on_all_associations(:belongs_to).map(&:foreign_key).map(&:to_sym)
      filters.uniq
    end

    def can_includes
      @can_includes || []
    end

    def can_include(*includes)
      @can_includes ||= []
      @can_includes += includes
    end

    private

    def side_load(include, models, options)
      association = association_from_include(include)

      if supported_association?(association)
        serializer = RestPack::Serializer::Factory.create(association.class_name)
        return send("side_load_#{association.macro}", association, models, serializer)
      else
        return {}
      end
    end

    def supported_association?(association)
      [:belongs_to, :has_many].include?(association.macro)
    end

    def side_load_belongs_to(association, models, serializer)
      foreign_keys = models.map { |model| model.send(association.foreign_key) }.uniq
      side_load = association.klass.find(foreign_keys)

      return {
        association.plural_name.to_sym => side_load.map { |model| serializer.as_json(model) },
        :meta => { }
      }
    end

    def side_load_has_many(association, models, serializer)
      return {} if models.empty?
      options = RestPack::Serializer::Options.new(serializer.class.model_class)
      options.filters = { association.foreign_key.to_sym => models.map(&:id) }
      return serializer.class.page_with_options(options)
    end

    def association_from_include(include)
      raise_invalid_include(include) unless self.can_includes.include?(include)

      possible_relations = [include.to_s.singularize.to_sym, include]
      possible_relations.each do |relation|
        association = self.model_class.reflect_on_association(relation)
        return association unless association.nil?
      end

      raise_invalid_include(include)
    end

    def raise_invalid_include(include)
      raise RestPack::Serializer::InvalidInclude.new,
        ":#{include} is not a valid include for #{self.model_class}"
    end
  end
end
