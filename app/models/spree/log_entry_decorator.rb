# workaround for issue https://github.com/spree/spree/issues/1767
# based on http://stackoverflow.com/questions/10427365/need-to-write-to-db-from-validation
Spree::LogEntry.class_eval do
  after_rollback :save_anyway

  def save_anyway
    log = Spree::LogEntry.new
    log.source  = source
    log.details = details
    log.save!
  end
end
