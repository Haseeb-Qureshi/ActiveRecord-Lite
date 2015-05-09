require_relative 'db_connection'
require_relative '02_searchable'
require 'active_support/inflector'

class SQLObject
  def self.columns
    query = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    query.first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method column do
        attributes[column]
      end

      define_method "#{column}=" do |value|
        attributes[column] = value
      end
    end
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
    results.map { |result| new(result) }
  end

  def self.find(id)
    me = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
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
    id.nil? ? insert : update
  end
end
