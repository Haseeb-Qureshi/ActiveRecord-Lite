require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method name do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      terminus = source_options.class_name.tableize
      join_table = through_options.class_name.tableize
      my_table = self.class.table_name

      query = DBConnection.execute(<<-SQL, id)[0]
        SELECT
          #{terminus}.*
        FROM
          #{terminus}
        JOIN
          #{join_table} ON #{join_table}.#{source_options.foreign_key} = #{terminus}.id
        JOIN
          #{my_table} ON #{self.class.table_name}.#{through_options.foreign_key} = #{join_table}.id
        WHERE
          #{my_table}.id = ?
      SQL

      attrs = query.each_with_object({}) { |(k, v), attrs| attrs[k.to_sym] = v }
      source_options.model_class.new(attrs)
    end
  end

  def has_many_through(name, through_name, source_name)
    define_method name do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      terminal_table = source_options.class_name.tableize
      through_table = through_options.class_name.tableize
      my_table = self.class.table_name

      has_manies = DBConnection.execute(<<-SQL, id)
        SELECT
          #{terminal_table}.*
        FROM
          #{terminal_table}
        JOIN
          #{through_table} ON #{through_table}.id = #{terminal_table}.#{source_options.foreign_key}
        JOIN
          #{my_table} ON #{my_table}.id = #{through_table}.#{through_options.foreign_key}
        WHERE
          #{my_table}.id = ?
      SQL

      has_manies.map do |instance|
        attrs = instance.each_with_object({}) { |(k, v), attrs| attrs[k.to_sym] = v }
        source_options.model_class.new(attrs)
      end
    end
  end
end
