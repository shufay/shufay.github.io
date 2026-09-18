## Liquid filter 'delimit' inserts thousands separators. Liquid has no
## equivalent, and the run totals are large enough that 214350 is hard to read.
## Usage {{ 214350 | delimit }} -> 214,350
#
module Jekyll
  module NumberFilters
    def delimit(input)
      number = input.to_s
      return number unless number.match?(/\A-?\d+(\.\d+)?\z/)

      sign = number.start_with?("-") ? "-" : ""
      whole, decimals = number.delete_prefix("-").split(".")
      grouped = whole.reverse.scan(/\d{1,3}/).join(",").reverse

      decimals ? "#{sign}#{grouped}.#{decimals}" : "#{sign}#{grouped}"
    end
  end
end

Liquid::Template.register_filter(Jekyll::NumberFilters)
