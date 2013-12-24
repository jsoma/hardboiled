{
    title: 'S3',
    tests: [
      {
        type: 'sudo',
        test: function(page) {
          var resource;
          for(var i = 0; i < page.resources.length; i++) {
            resource = page.resources[i];
            for(var j = 0;j < resource.headers.length; j++) {
              if(resource.headers[j].name == 'Server' && resource.headers[j].value === 'AmazonS3') {
                return true;
              }
            }
          }
        }
      }
    ]
}