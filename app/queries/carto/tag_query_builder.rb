# encoding: UTF-8

require 'active_record'

class Carto::TagQueryBuilder

  def initialize(user_id)
    @user_id = user_id
  end

  def build_paged(page, per_page)
    limit = per_page.to_i
    offset = (page.to_i - 1) * per_page.to_i
    query = ActiveRecord::Base.send(:sanitize_sql_array, [sql_query, @user_id, limit, offset])

    connection = ActiveRecord::Base.connection
    result = connection.exec_query(query)

    format_response(result)
  end

  private

  def sql_query
    %{
      SELECT LOWER(unnest(tags)) AS tag,
        SUM(CASE type WHEN 'derived' THEN 1 ELSE 0 END) AS derived_count,
        SUM(CASE type WHEN 'table' THEN 1 ELSE 0 END) AS table_count
      FROM visualizations
      WHERE user_id = ?
        AND array_length(tags, 1) > 0
      GROUP BY tag
      ORDER BY COUNT(*) DESC
      LIMIT ?
      OFFSET ?
    }.squish
  end

  def format_response(result)
    result.map do |row|
      {
        tag: row['tag'],
        maps: row['derived_count'].to_i,
        datasets: row['table_count'].to_i
      }
    end
  end

end
