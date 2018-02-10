require 'csv'

class Result < ApplicationRecord
  def parsed_data
    return [] unless data
    @parsed_data ||= CSV.parse(data)
    # @parsed_data ||= CSV.parse(data, headers: true)
  end

  def headers
    return [] unless data
    parsed_data[0]
  end

  def rows(limit = nil)
    return [] unless data
    _rows = parsed_data[1..-1]
    _rows = _rows.first(limit) if limit
    _rows
  end
end