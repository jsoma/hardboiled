{
    title: 'EdgeCast',
    url: 'http://www.edgecast.com/',
    tests: [
      {
        type: 'header',
        test: { 'Server': /^ECS (.*)/ }
      }
      //,  {
      //   type: 'server',
      //   test: /cloudflare-(.*)/
      // }      
    ]
}