module DataFormatEnumerations
  extend Enumerize
  extend ActiveModel::Naming

  enumerize :data_format, in: %w[neptune netex gtfs hub], default: "netex"
end
