require_relative 'db_connection'
require_relative '01_sql_object'
require_relative 'relation'
require_relative 'validatable'

module Searchable

  def deprecated_where(params)
    lookup = params.keys.map { |key| "#{key} = ?" }.join(" AND ")
    query = DBConnection.execute(<<-SQL, *params.values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{lookup}
    SQL
    query.map { |attrs| new(attrs) }
  end

  def where(params)
    Relation.new(params, table_name)
  end
end

class SQLObject
  extend Searchable
  include Validatable
end
