{
    title: 'RGB color parser',
    url: 'http://www.phpied.com/rgb-color-parser-in-javascript/',
    description: 'A JavaScript class that accepts a string and tries to figure out a valid color out of it.',
    tests: [
      {
        type: 'javascript',
        test: function() {
          try {
            var color = new RGBColor('darkblue');
            return !!color.ok && !!color.toRGB
          } catch(err) { }
          return false;
        }
      }
    ]
}