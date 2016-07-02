def newly_appeared(today, yesterday, *list)
  diff = today.map { |service| service.dig(*list) }.compact.sort.uniq - yesterday.map { |service| service.dig(*list) }
  diff.compact.sort.uniq.map { |d| [d, ''] }
end

def xss_filter(input_text)
  String(input_text).gsub(/[^0-9A-Za-z\ ]/, '')
end

def parse_date(input)
  if input.nil? || input.empty?
    date = Date.today
  else
    date = Date.parse(xss_filter(input))
  end
  date
end