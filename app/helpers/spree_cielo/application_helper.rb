module SpreeCielo
  module ApplicationHelper
    def format_xml source
      indented = Nokogiri::XML(source).to_xml

      escaped = CGI::escapeHTML indented
      escaped.gsub! " ", "&nbsp;"
      escaped.gsub! "\n", "<br />"

      escaped.html_safe
    end
  end
end
