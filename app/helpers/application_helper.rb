module ApplicationHelper
  include Pagy::HelperLoader

  def risk_badge(level)
    css = case level&.to_s
    when "safe" then "badge-safe"
    when "low" then "badge-low"
    when "medium" then "badge-medium"
    when "high" then "badge-high"
    when "critical" then "badge-critical"
    else "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold border bg-gray-500/20 border-gray-500/30 text-gray-400"
    end
    content_tag(:span, level&.capitalize || "Unknown", class: css)
  end

  def risk_score_color(score)
    return "text-gray-400" unless score
    case score
    when 0..20 then "text-green-400"
    when 21..40 then "text-yellow-400"
    when 41..60 then "text-orange-400"
    when 61..80 then "text-red-500"
    else "text-red-700"
    end
  end
end
