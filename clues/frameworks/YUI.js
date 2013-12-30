{
    title: 'YUI',
    url: 'http://yuilibrary.com',
    description: 'YUI is a free, open source JavaScript and CSS library for building richly interactive web applications.',
    tags: 'yui',
    tests: [
      {
        type: 'javascript',
        test: function() {
          if(!!window.YUI) {
            return { version: YUI.version };
          }
        }
      }
    ]
}