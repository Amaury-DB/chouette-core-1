object @stop_area

node do |s|
  {
    type: 'Feature',
    geometry: {
      type: 'Point',
      coordinates: [s.longitude, s.latitude]
    },
    properties: {
      name: s.name
    }
  }
end