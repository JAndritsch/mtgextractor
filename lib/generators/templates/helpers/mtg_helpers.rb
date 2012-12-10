module MtgHelpers
  def slugify(word)
    word.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  end
end
