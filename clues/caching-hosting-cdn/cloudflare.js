{
    title: 'CloudFlare',
    url: 'http://www.cloudflare.com',
    tests: [
      {
        type: 'header',
        test: 'CF-Cache-Status'
      }
      //,  {
      //   type: 'server',
      //   test: /cloudflare-(.*)/
      // }      
    ]
}