{
    title: 'requireJS',
    url: 'http://requirejs.org',
    description: 'RequireJS is a JavaScript file and module loader.',
    tests: [
      {
        type: 'javascript',
        test: function() {
          if(!!window.requirejs) {
            return { version: requirejs.version };
          }
        }
      }
    ]
}