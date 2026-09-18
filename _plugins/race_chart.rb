## Liquid tag 'race_chart' renders the races in _data/races.yml as a build-time
## inline SVG (small multiples, one panel per distance) followed by a results
## table. No JavaScript: all geometry is computed here, during `jekyll build`.
##
## Usage {% race_chart %}
##       {% race_chart 'metric=pace' %}
##       {% race_chart 'events=marathon' %}
##
## This tag emits geometry and structure only -- no colors, fonts or sizes.
## Everything visual lives in the .rc-* rules in _sass/_custom.scss.
#
require "shellwords"
require "digest"
require "cgi"
require "date"

module Jekyll
  class RenderRaceChartTag < Liquid::Tag
    # Canonical distances in miles, so _data/races.yml stays symbolic.
    DISTANCES    = { "marathon" => 26.2188, "half" => 13.1094 }.freeze
    PANEL_LABELS = { "marathon" => "Marathon", "half" => "Half marathon" }.freeze
    DEFAULT_EVENTS = %w[marathon half].freeze

    # Axis step ladders, coarsest step last. Every entry is a whole number of
    # minutes (seconds, for pace), so a tick label is always exact and never
    # rounds a :45 away. Picking from a fixed ladder avoids needing a general
    # nice-number algorithm.
    TIME_STEPS = [60, 120, 300, 600, 900, 1800, 3600].freeze
    PACE_STEPS = [5, 10, 15, 20, 30, 60, 120].freeze
    MAX_TICKS  = 5

    # Panel geometry, in viewBox units.
    W        = 560
    LEFT     = 54
    RIGHT    = 14
    PLOT_TOP = 30
    PLOT_H   = 148
    XLABEL_H = 26
    PLOT_W   = W - LEFT - RIGHT
    PLOT_BOT = PLOT_TOP + PLOT_H
    PANEL_H  = PLOT_BOT + XLABEL_H

    def initialize(tag_name, markup, tokens)
      super
      @opts = {}
      markup.to_s.shellsplit.each do |arg|
        key, value = arg.split("=", 2)
        @opts[key.to_s.strip] = value.to_s.strip
      end
    end

    def render(context)
      site = context.registers[:site]
      rows = normalize(site.data["races"])
      return "" if rows.empty?

      metric = @opts["metric"] == "pace" ? "pace" : "time"
      events = @opts.fetch("events", "").split(",").map { |e| e.strip.downcase }
      events = DEFAULT_EVENTS if events.empty?
      events &= DEFAULT_EVENTS

      series = events.map { |e| [e, rows.select { |r| r[:event] == e && r[:plottable] }] }
                     .reject { |_event, rs| rs.empty? }

      [chart(series, metric), table(rows)].compact.join("\n")
    end

    private

    # --- data -------------------------------------------------------------

    def normalize(raw)
      return [] unless raw.is_a?(Array)

      raw.filter_map do |row|
        next unless row.is_a?(Hash)

        event = row["event"].to_s.strip.downcase
        date  = to_date(row["date"])
        secs  = to_seconds(row["time"])
        miles = DISTANCES[event] || to_float(row["distance_mi"])

        {
          event:     event,
          name:      row["name"].to_s,
          date:      date,
          secs:      secs,
          miles:     miles,
          pace:      (secs && miles && miles > 0 ? secs / miles : nil),
          pr:        row["pr"] == true,
          status:    row["status"].to_s.strip,
          location:  row["location"].to_s.strip,
          notes:     row["notes"].to_s.strip,
          plottable: !date.nil? && !secs.nil? && DISTANCES.key?(event)
        }
      end
    end

    def to_date(value)
      case value
      when Date then value
      when Time then value.to_date
      when String
        begin
          Date.parse(value)
        rescue ArgumentError
          nil
        end
      end
    end

    # Horner's method in base 60, so "MM:SS" and "H:MM:SS" parse with the same
    # code -- folding left over base 60 is scale-invariant.
    def to_seconds(value)
      text = value.to_s.strip
      return nil unless text.match?(/\A\d+(:\d{1,2})+\z/) || text.match?(/\A\d+\z/)

      text.split(":").map(&:to_i).inject(0) { |acc, part| acc * 60 + part }
    end

    def to_float(value)
      return nil if value.nil? || value.to_s.strip.empty?

      Float(value)
    rescue ArgumentError, TypeError
      nil
    end

    def value_of(row, metric)
      metric == "pace" ? row[:pace] : row[:secs]
    end

    # --- scales -----------------------------------------------------------

    # Snap the domain outward to multiples of the coarsest ladder step that
    # keeps the tick count at or below MAX_TICKS.
    def domain(values, steps)
      lo = values.min
      hi = values.max

      if hi == lo
        pad = steps[2] / 2 # a single race: force a legible window around it
        lo -= pad
        hi += pad
      end

      step = steps.find { |s| (hi - lo).to_f / s <= MAX_TICKS } || steps.last
      dlo  = (lo.to_f / step).floor * step
      dhi  = (hi.to_f / step).ceil * step
      dhi += step if dhi == dlo

      [dlo, dhi, step]
    end

    # Julian day numbers, not epoch seconds: integer, timezone-free, so a
    # quoted vs unquoted YAML date can never shift a point sideways.
    def x_of(date, x0, x1)
      LEFT + (date.jd - x0.jd) * PLOT_W.to_f / (x1.jd - x0.jd)
    end

    def y_of(value, lo, hi)
      PLOT_BOT - (value - lo) * PLOT_H.to_f / (hi - lo)
    end

    # Landing the domain on January 1 boundaries gives clean ticks and padding
    # in one move, so no separate padding rule is needed.
    def x_domain(rows)
      years = rows.map { |r| r[:date].year }
      [Date.new(years.min, 1, 1), Date.new(years.max + 1, 1, 1)]
    end

    # Returns [date, label, labeled?]. Every tick gets a gridline; only some
    # get a label, so thinning never recomputes the geometry.
    def x_ticks(x0, x1)
      if x1.year - x0.year <= 1
        [1, 4, 7, 10].map { |m| [Date.new(x0.year, m, 1), Date::ABBR_MONTHNAMES[m], true] }
      else
        years = (x0.year..x1.year).to_a
        every = (years.size / 8.0).ceil
        years.each_with_index.map { |y, i| [Date.new(y, 1, 1), y.to_s, (i % every).zero?] }
      end
    end

    # --- formatting -------------------------------------------------------

    def fmt_clock(secs)
      h, rem = secs.round.divmod(3600)
      m, s   = rem.divmod(60)
      h > 0 ? format("%d:%02d:%02d", h, m, s) : format("%d:%02d", m, s)
    end

    # axis_max makes the choice of H:MM vs MM:SS a property of the whole axis,
    # not of each value: an axis that mixed "58:00" with "1:00" would read as
    # though the second label were one minute.
    def fmt_tick(secs, metric, axis_max = nil)
      total = secs.round
      return format("%d:%02d", *total.divmod(60)) if metric == "pace"

      h, rem = total.divmod(3600)
      m, s   = rem.divmod(60)
      (axis_max || total) >= 3600 ? format("%d:%02d", h, m) : format("%d:%02d", m, s)
    end

    def fmt_value(row, metric)
      metric == "pace" ? "#{fmt_tick(row[:pace], 'pace')}/mi" : fmt_clock(row[:secs])
    end

    def trim_num(value)
      value == value.to_i ? value.to_i.to_s : format("%.1f", value)
    end

    def esc(text)
      CGI.escapeHTML(text.to_s)
    end

    # --- chart ------------------------------------------------------------

    def chart(series, metric)
      return nil if series.empty?

      steps    = metric == "pace" ? PACE_STEPS : TIME_STEPS
      all_rows = series.flat_map { |_event, rs| rs }
      x0, x1   = x_domain(all_rows)
      ticks    = x_ticks(x0, x1)

      # Pace is comparable across distances, so those panels share one scale;
      # finish times are not, so each panel gets its own well-fit domain.
      shared = metric == "pace" ? domain(all_rows.map { |r| value_of(r, metric) }, steps) : nil

      uid = Digest::MD5.hexdigest(all_rows.map { |r| "#{r[:name]}#{r[:date]}" }.join)[0, 6]

      out = []
      out << %(<figure class="rc-figure">)
      out << %(<div class="rc-scroll">)
      out << %(<svg class="rc-svg" viewBox="0 0 #{W} #{PANEL_H * series.size}" ) +
             %(preserveAspectRatio="xMidYMid meet" role="img" ) +
             %(aria-labelledby="rc-t-#{uid} rc-d-#{uid}" focusable="false">)
      out << %(<title id="rc-t-#{uid}">#{esc(chart_title(series, x0, x1, metric))}</title>)
      out << %(<desc id="rc-d-#{uid}">#{esc(chart_desc(series, metric))}</desc>)

      series.each_with_index do |(event, rs), i|
        ydom = shared || domain(rs.map { |r| value_of(r, metric) }, steps)
        out << panel(event, rs, i, x0, x1, ticks, ydom, metric, i == series.size - 1)
      end

      out << "</svg>"
      out << "</div>"
      out << %(<figcaption>#{esc(caption(metric, series.size))}</figcaption>)
      out << "</figure>"
      out.join("\n")
    end

    def panel(event, rows, index, x0, x1, ticks, ydom, metric, show_x_labels)
      lo, hi, step = ydom
      out = []
      out << %(<g class="rc-panel" transform="translate(0,#{index * PANEL_H})">)
      out << %(<text class="rc-panel-title" x="#{LEFT}" y="18">#{esc(PANEL_LABELS[event])}</text>)

      out << %(<g class="rc-grid">)
      each_y_tick(lo, hi, step) do |value, y|
        out << %(<line x1="#{LEFT}" y1="#{y}" x2="#{W - RIGHT}" y2="#{y}"/>)
      end
      out << "</g>"

      out << %(<g class="rc-ticks rc-ticks-y">)
      each_y_tick(lo, hi, step) do |value, y|
        out << %(<text x="#{LEFT - 8}" y="#{(y + 4).round(2)}" text-anchor="end">) +
               %(#{fmt_tick(value, metric, hi)}</text>)
      end
      out << "</g>"

      out << %(<g class="rc-grid rc-grid-x">)
      ticks.each do |date, _label, labeled|
        x = x_of(date, x0, x1).round(2)
        attrs = labeled ? "" : %( class="rc-x-alt")
        out << %(<line#{attrs} x1="#{x}" y1="#{PLOT_TOP}" x2="#{x}" y2="#{PLOT_BOT}"/>)
      end
      out << "</g>"

      out << %(<line class="rc-axis" x1="#{LEFT}" y1="#{PLOT_BOT}" x2="#{W - RIGHT}" y2="#{PLOT_BOT}"/>)

      if show_x_labels
        out << %(<g class="rc-ticks rc-ticks-x">)
        ticks.each do |date, label, labeled|
          next unless labeled

          out << %(<text x="#{x_of(date, x0, x1).round(2)}" y="#{PLOT_BOT + 18}" ) +
                 %(text-anchor="middle">#{esc(label)}</text>)
        end
        out << "</g>"
      end

      points = rows.sort_by { |r| r[:date] }
                   .map { |r| [x_of(r[:date], x0, x1), y_of(value_of(r, metric), lo, hi), r] }

      if points.size > 1
        coords = points.map { |x, y, _r| "#{x.round(2)},#{y.round(2)}" }.join(" ")
        out << %(<polyline class="rc-line" points="#{coords}"/>)
      end

      points.each do |x, y, r|
        klass = r[:pr] ? "rc-dot rc-dot-pr" : "rc-dot"
        out << %(<circle class="#{klass}" cx="#{x.round(2)}" cy="#{y.round(2)}" r="4.5"/>)
      end

      # Direct-label the fastest and the most recent race only: a value beside
      # every point goes unread.
      labelled = [rows.min_by { |r| value_of(r, metric) }, points.last[2]].uniq
      labelled.each do |r|
        x = x_of(r[:date], x0, x1)
        y = y_of(value_of(r, metric), lo, hi)
        ly = (y - 12 > PLOT_TOP ? y - 11 : y + 19).round(2)
        anchor =
          if x < LEFT + 32 then "start"
          elsif x > W - RIGHT - 32 then "end"
          else "middle"
          end
        out << %(<text class="rc-value" x="#{x.round(2)}" y="#{ly}" text-anchor="#{anchor}">) +
               %(#{esc(fmt_value(r, metric))}</text>)
      end

      out << "</g>"
      out.join("\n")
    end

    def each_y_tick(lo, hi, step)
      value = lo
      while value <= hi
        yield value, y_of(value, lo, hi).round(2)
        value += step
      end
    end

    # --- prose ------------------------------------------------------------

    def chart_title(series, x0, x1, metric)
      names = series.map { |event, _rs| PANEL_LABELS[event].downcase }.join(" and ")
      what  = metric == "pace" ? "pace per mile" : "finish times"
      "#{names.capitalize} #{what}, #{x0.year} to #{x1.year - 1}"
    end

    # Generated from the data, so a screen reader gets the shape of the trend
    # rather than a bare "chart".
    def chart_desc(series, metric)
      what = metric == "pace" ? "Pace" : "Finish time"
      lead = series.size == 1 ? "A line chart." : "#{series.size} line charts sharing a year axis."

      sentences = series.map do |event, rows|
        sorted = rows.sort_by { |r| r[:date] }
        best   = rows.min_by { |r| value_of(r, metric) }
        count  = "#{rows.size} #{rows.size == 1 ? 'race' : 'races'}"

        if rows.size == 1
          "#{PANEL_LABELS[event]}: #{count}, #{what.downcase} " \
            "#{fmt_value(sorted.first, metric)} in #{sorted.first[:date].year}."
        else
          "#{PANEL_LABELS[event]}: #{count}. #{what} went from " \
            "#{fmt_value(sorted.first, metric)} in #{sorted.first[:date].year} to " \
            "#{fmt_value(sorted.last, metric)} in #{sorted.last[:date].year}; " \
            "best #{fmt_value(best, metric)} at #{best[:name]}."
        end
      end

      ([lead] + sentences + ["Full results follow in the table below."]).join(" ")
    end

    def caption(metric, panel_count)
      return "Road race pace per mile. Both panels share the same vertical scale and the year axis." if metric == "pace"

      base = "Road race finish times."
      panel_count > 1 ? "#{base} Each panel has its own vertical scale; the year axis is shared." : base
    end

    # --- table ------------------------------------------------------------

    # Always visible, not a fallback: on a running page the race list is what a
    # reader wants, and it is also where every value stays reachable without
    # reading the chart.
    def table(rows)
      return nil if rows.empty?

      out = []
      out << %(<table class="rc-table">)
      out << "<thead><tr><th>Date</th><th>Race</th><th>Distance</th>" \
             "<th>Time</th><th>Pace/mi</th><th>Notes</th></tr></thead>"
      out << "<tbody>"

      rows.sort_by { |r| r[:date] || Date.new(0) }.reverse_each do |r|
        date  = r[:date] ? r[:date].strftime("%b %-d, %Y") : "&mdash;"
        dist  = PANEL_LABELS[r[:event]] || (r[:miles] ? "#{trim_num(r[:miles])} mi" : "&mdash;")
        time  = if r[:secs] then fmt_clock(r[:secs])
                elsif r[:status].empty? then "&mdash;"
                else esc(r[:status])
                end
        pace  = r[:pace] ? fmt_tick(r[:pace], "pace") : "&mdash;"
        notes = [r[:location], r[:notes]].reject(&:empty?).map { |t| esc(t) }.join(" &middot; ")
        notes = "&mdash;" if notes.empty?

        out << "<tr><td>#{date}</td><td>#{esc(r[:name])}</td><td>#{dist}</td>" \
               "<td>#{time}</td><td>#{pace}</td><td>#{notes}</td></tr>"
      end

      out << "</tbody></table>"
      out.join("\n")
    end
  end
end

Liquid::Template.register_tag('race_chart', Jekyll::RenderRaceChartTag)

# jekyll-target-blank reparses every rendered page through Nokogiri's HTML4
# serializer, which lowercases all attribute names. SVG attribute names are
# case-sensitive, so `viewBox` comes back as `viewbox`, the browser ignores it,
# and the chart renders at its intrinsic size instead of scaling to the column.
# Restore the camelCase spellings afterwards: :low priority sorts after the
# default :normal that target-blank registers with.
Jekyll::Hooks.register [:pages, :documents], :post_render, priority: :low do |doc|
  output = doc.output
  next unless output.is_a?(String) && output.include?("rc-svg")

  output = output.gsub("viewbox=", "viewBox=")
                 .gsub("preserveaspectratio=", "preserveAspectRatio=")
  doc.output = output
end
