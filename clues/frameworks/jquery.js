{
    title: 'jQuery',
    url: 'http://jquery.com',
    description: 'jQuery is a fast, small, and feature-rich JavaScript library.',
    tags: 'jquery',
    tests: [
      {
        type: 'javascript',
        test: function() {
          var keys = Object.keys(window);
          var val, key;

          for(var i=0;i<keys.length;i++) {
            key = keys[i];
            if(window[key] != null && window[key].fn != null && window[key].fn.jquery != null) {
              return { version: window[key].fn.jquery };
            }
          }
        }
      }
    ]
}