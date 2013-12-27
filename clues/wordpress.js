{
    title: 'Wordpress',
    url: 'http://www.wordpress.org',
    tests: [
      {
        type: 'meta',
        test: {
          name: 'generator',
          content: /^WordPress ?(.*)/i
        }
      }
    ]
}