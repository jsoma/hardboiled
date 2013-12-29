{
    title: 'Stamen Tile Layer',
    url: 'http://maps.stamen.com',
    tests: [
      {
        type: 'javascript',
        test: function() {
          return (!!L && !!L.StamenTileLayer) ||
            (!!OpenLayers && !!OpenLayers.Layer && !!OpenLayers.Layer.Stamen) ||
            (!!google && !!google.maps && !!google.maps.StamenMapType);
        }
      }
    ]
}