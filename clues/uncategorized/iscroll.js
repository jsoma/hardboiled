{
    title: 'iScroll',
    url: 'http://cubiq.org/iscroll-4',
    tests: [
      {
        type: 'javascript',
        test: function() {
          return !!iScroll && !!iScroll.prototype._wheel;
        }
      }
    ]
}