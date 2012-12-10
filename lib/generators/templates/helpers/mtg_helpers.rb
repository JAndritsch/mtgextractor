module MtgHelpers
  def slugify(word)
    word.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  end

  def using_asset_pipeline?
    config = Rails.application.config
    config.respond_to?(:assets) && config.assets.try(:enabled)
  end

  def asset_pipeline_prefix
    Rails.application.config.assets.prefix
  end
end
