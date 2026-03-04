module ApplicationHelper
  DAY_LABELS = { 0 => "Dim.", 1 => "Lun.", 2 => "Mar.", 3 => "Mer.", 4 => "Jeu.", 5 => "Ven.", 6 => "Sam." }.freeze

  def format_date_label(date)
    today = Date.today
    if date == today         then "aujourd'hui"
    elsif date == today + 1  then "demain"
    elsif date == today - 1  then "hier"
    else l(date, format: "%d %B %Y")
    end
  end
end
