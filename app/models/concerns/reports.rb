module Reports
  class Collection
    def initialize(reports)
      @reports = reports
    end

    def all
      self
    end

    def where
      self.class.new(all.select do |report|
        yield(report)
      end)
    end

    def find(id)
      @reports.find{ |report| report.code == id }
    end

    def method_missing(method, *args, &block)
      return @reports.send(method, *args, &block) if @reports.respond_to?(method)
      super
    end
  end

  class << self
    def collection
      Collection.new(Reports::BaseReport.descendants)
    end

    delegate :all, :where, :find, to: :collection
  end
end