module LargeEnsemblesHelper
  def display_name_with_abbreviation(performance_class)
    if performance_class.abbreviation.present?
      "#{performance_class.abbreviation} - #{performance_class.name}"
    else
      performance_class.name
    end
  end
end
