class String
  def clean_up_tags
    gsub(/,/, '').gsub(' ', ', ')
  end
end