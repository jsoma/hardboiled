{
    title: 'jQuery inview',
    url: 'https://github.com/protonet/jquery.inview',
    tags: 'jquery',
    tests: [
      {
        type: 'javascript',
        test: function() {
          var keys = Object.keys(window);
          var val, key, foundjQ;

          for(var i=0;i<keys.length;i++) {
            key = keys[i]
            if(window[key] && window[key].fn && window[key].fn.jquery) {
              foundjQ = window[key];
            }
          }
          
          if(!foundjQ)
            return false;
          
          return !!foundjQ.event.special.inview
        }
      }
    ]
}