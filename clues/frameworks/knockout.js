{
    title: 'Knockout.js',
    url: 'http://knockoutjs.com',
    description: 'Knockout is a JavaScript library that helps you to create rich, responsive display and editor user interfaces with a clean underlying data model.',
    tests: [
      {
        type: 'javascript',
        test: function() {
          if(!!window.ko) {
            return { version: ko.version };
          }
        }
      }
    ]
}