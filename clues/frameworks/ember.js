{
    title: 'Ember.js',
    url: 'http://www.emberjs.com',
    description: 'A framework for creating ambitious web application',
    tags: 'emberjs',
    tests: [
      {
        type: 'javascript',
        test: function() {
          if(!!window.Ember) {
            return { version: Ember.VERSION };
          }
        }
      }
    ]
}