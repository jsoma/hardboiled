{
    title: 'queue.js',
    url: 'https://github.com/mbostock/queue',
    description: 'Queue.js is yet another asynchronous helper library for JavaScript.',
    tests: [
      {
        type: 'javascript',
        test: function() {
          try {
            return !!queue() && !!queue().defer && queue().awaitAll
          } catch(err) { }
          return false;
        }
      }
    ]
}