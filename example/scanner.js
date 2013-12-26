var hardboiled = require('../lib/hardboiled');

var scanner = new hardboiled.Scanner({});
var url = "http://handsomeatlas.com";

scanner.scan({url: url}, function(err, page) {
  console.log("URL is " + page.url);
  // URL is http://handsomeatlas.com
  
  page.matches.forEach(function(match, i) {
    console.log("Match " + (i + 1) + ":");
    console.log(match);
  });
  
  // Match 1:
  // { title: 'Twitter Bootstrap, Responsive CSS',
  //   description: 'Prior to Bootstrap 3, you could enable responsive design by adding in an additional stylesheet.',
  //   url: 'http://getbootstrap.com',
  //   data: [ { matches: [Object] } ] }
  // Match 2:
  // { title: 'Bootstrap',
  //   description: undefined,
  //   url: 'http://getbootstrap.com',
  //   data: [ { matches: [Object] } ] }
  // Match 3:
  // { title: 'Google Analytics',
  //   description: undefined,
  //   url: 'http://www.google.com/analytics',
  //   data: [ { matches: [Object] } ] }
  // Match 4:
  // { title: 'Facebook Like button',
  //   description: undefined,
  //   url: undefined,
  //   data: [] }
  // Match 5:
  // { title: 'jQuery',
  //   description: undefined,
  //   url: 'http://jquery.com',
  //   data: [ { version: '1.7.1' } ] }
  
})