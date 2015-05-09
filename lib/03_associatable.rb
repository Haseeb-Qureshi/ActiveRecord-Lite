require_relative '02_searchable'
require 'active_support/inflector'
require_relative 'active_support_patches'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    Object.const_get(@class_name)
  end

  def table_name
    @class_name.tableize
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || (name.to_s.underscore + '_id').to_sym
    @class_name = options[:class_name] || name.capitalize.to_s
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {}) # YOU'RE HERE
    @foreign_key = options[:foreign_key] || (self_class_name.to_s.underscore.singularize + '_id').to_sym
    @class_name = options[:class_name] || name.to_s.singularize.camelcase
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options(name, options)

    define_method name do
      id = send(options.foreign_key)
      options.model_class.where(:id => id).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    assoc_options(name, options)

    define_method name do
      options.model_class.where(options.foreign_key => id)
    end
  end

  def assoc_options(name = nil, association = {})
    @assoc_options ||= {}
    @assoc_options[name] = association unless name.nil?
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
