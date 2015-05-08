require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  # def self.my_attr_accessor(*names)
  #   names.each do |name|
  #     define_method name do
  #       instance_variable_get "@#{name}"
  #     end
  #     define_method "#{name}=" do |val|
  #       instance_variable_set "@#{name}", val
  #     end
  #   end
  # end

  def self.columns
    query = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    columns = query.first.map(&:to_sym)
    @attributes = Hash.new(columns.zip([nil]))
    columns.each do |column|
      define_method column do
        attributes[column]
      end

      define_method "#{column}=" do |value|
        attributes[column] = value
      end
    end
    columns
  end

  def self.finalize!
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || name.tableize
  end

  def self.all
    parse_all(DBConnection.execute(<<-SQL))
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL
  end

  def self.parse_all(results)
    results.inject([]) { |all, result| all << new(result) }
  end

  def self.find(id)
    me = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = #{id}
    SQL
    return nil if me.empty?
    new(me.first.each_with_object({}) { |(k, v), hash| hash[k.to_sym] = v } )
  end

  def initialize(params = {})
    params.each do |column, value|
      raise "unknown attribute '#{column}'" unless respond_to? column
      self.send("#{column}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    col_names = "(" + attributes.keys.map(&:to_s).join(", ") + ")"
    question_marks = "(" + (['?'] * attribute_values.size).join(', ') + ")"
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} #{col_names}
      VALUES
        #{question_marks}
    SQL
    attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    set = attributes.keys.map { |attr| "#{attr} = ?" }.join(", ")
    DBConnection.execute(<<-SQL, *(attribute_values << id))
      UPDATE
        #{self.class.table_name}
      SET
        #{set}
      WHERE
        id = ?
    SQL
  end

  def save
    attributes[id].nil? ? insert : update
  end
end
