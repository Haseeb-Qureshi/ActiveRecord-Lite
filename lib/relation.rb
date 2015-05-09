class Relation
  attr_reader :table_name
  include Enumerable

  def initialize(params, table_name)
    @params = params
    @table_name = table_name
  end

  def where(params)
    Relation.new(@params.merge(params), @table_name)
  end

  def load
    lookup = @params.keys.map { |key| "#{key} = ?" }.join(" AND ")
    query = DBConnection.execute(<<-SQL, *@params.values)
      SELECT
        *
      FROM
        #{@table_name}
      WHERE
        #{lookup}
    SQL
    query.map { |attrs| Object.const_get(@table_name.camelcase.singularize).new(attrs) }
  end

  def cache
    @cache ||= load
  end

  def ==(other_obj)
    cache == other_obj
  end

  def method_missing(m, *args, &blk)
    return cache.send(m, *args, &blk) if cache.respond_to?(m)
    raise NoMethodError
  end
end
