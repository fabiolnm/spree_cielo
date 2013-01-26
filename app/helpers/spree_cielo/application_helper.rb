module SpreeCielo
  module ApplicationHelper
    def format_xml source
      indented = Nokogiri::XML(source).to_xml.force_encoding "UTF-8"

      escaped = CGI::escapeHTML indented
      escaped.gsub! " ", "&nbsp;"
      escaped.gsub! "\n", "<br />"

      escaped.html_safe
    end
  end
end
