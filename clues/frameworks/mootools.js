{
    title: 'MooTools',
    url: 'http://www.mootools.com',
    description: 'MooTools is a compact, modular, Object-Oriented JavaScript framework designed for the intermediate to advanced JavaScript developer.',
    tags: 'mootools',
    tests: [
      {
        type: 'javascript',
        test: function() {
          if(!!window.MooTools) {
            return { version: MooTools.version };
          }
        }
      }
    ]
}