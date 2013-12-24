# Hardboiled!

**Hardboiled** is a detective kit for investigating **how web sites are built.** It runs JavaScript, scrapes stylesheets, and isn't afraid to **break a few bones** to get the job done. It tracks down frameworks, jQuery plugins, grid systems, and anything else your dark heart desires.

*Hardboiled is a work-in-progress like **crazy**. I've never written node anything before, and it's really just up so I can hassle folks for feedback. The ever-so-convenient web app is on its way.*

## Introduction

You use it like this:

```
hardboiled = require('hardboiled')

// When you scan, you get back a Hardboiled.Page object that can do all sorts of stuff. These are the basics you're looking for.
hardboiled.scan("http://handsomeatlas.com", function(err, page) {
  console.log(page.url)
  // http://handsomeatlas.com
  
  page.matches.forEach(function(match) {
    console.log(match)
  }
  // Match 1:
  // { title: 'Google Analytics',
  //   description: undefined,
  //   url: 'http://www.google.com/analytics' }
  // Match 2:
  // { title: 'Twitter Bootstrap, Responsive CSS',
  //   description: 'Prior to Bootstrap 3, you could enable responsive design by adding in an additional stylesheet.',
  //   url: 'http://getbootstrap.com' }
  // Match 3:
  // { title: 'Bootstrap',
  //   description: undefined,
  //   url: 'http://getbootstrap.com' }
  // Match 4:
  // { title: 'jQuery',
  //   description: undefined,
  //   url: 'http://jquery.com' }
  // Match 5:
  // { title: 'Facebook Like button',
  //   description: undefined,
  //   url: undefined }

})
```

## How it works

**Hardboiled** is based on clue files, which are JSON-y files describing different technologies. They live (or will live) cluttered in various subdirectories in `/clues/`, although you can specify other directories if you'd like.

Invoke Hardboiled like so:

```
Hardboiled.scan("http://www.google.com", function (err, page) {
  // page is the Hardboiled.Page object, you'
  console.log('Requested ' + page.url);
  console.log('Processed ' + page.resources.length + ' attached resources.');
  console.log('Technology matches:')
  page.matches.forEach( function(match) {
    console.log(match.title + ' ' + match.description);
    console.log()
  })
})
```

We can only detect as many technologies as we have clues for, so please be a hero and contribute wicked-awesome clues.

## Clue Format

Hardboiled depends on user-submitted clues to decipher the web. Each clue file describes the technology that's being looked for and includes the tests needed to figure out if the page is using the technology.

```
{
    title: "Facebook Like button (iframe version)",
    description: "This is the ubiquitous button that is used to 'Like' a page. The iframe version has the ability to comment.",
    url: "https://developers.facebook.com/docs/plugins/like-button/",
    tags: "social, facebook",
    tests: [
      {
        type: 'selector', 
        test: 'iframe[src^="http://www.facebook.com/plugins/like.php"]'
      }
    ]
}
```

This one's for the iframe version of the [Facebook Like button](https://developers.facebook.com/docs/plugins/like-button/). Its only test looks for an iframe with a particular `src`. If you have multiple tests, it only takes passing one to validate the clue.

#### Folders themselves

I have no clue how to organize these.

### Technology Info

The technology can be described using a `title`, `description`, `url`, and comma-delited `tags`. The technology is tested using an array of `tests`.

Tags covering a category should be kept plural (e.g. **frameworks** not **framework**).

### Test types

Tests each have a `type` and a `test`.

Types of tests are `filename`, `selector`, `global`, `javascript` and `sudo`.

#### filename

`filename` looks for JavaScript or stylesheet files with a given name. It also does some normalization and stripping, so 'bootstrap-reponsive' will match 'bootstrap-responsive.min.css'.

```
{
  type: 'filename',
  test: 'bootstrap-responsive'
}
```

`filename` is the easiest (and least effective) type of test, but it's a pretty good start. Send a pull and later on maybe someone will upgrade it to something a bit fancier? Check out the jQuery example under `javascript` to see what kind of improvements that could be made beyond looking for a file named `jquery.js`.

#### selector

`selector` looks for an element on the page. This example looks for the embedded version of [TimelineJS](http://timeline.knightlab.com), an iframe beginning with `http://embed.verite.co/timeline`.

```
{
  type: 'selector', 
  test: 'iframe[src^='http://embed.verite.co/timeline']'
}
```

#### global

`global` checks if a variable/function/etc with that name exists off of the `window` object on the page. You could naively look for jQuery by trying to find '$', but this example looks for [TimelineJS](http://timeline.knightlab.com)/[StoryJS](https://github.com/NUKnightLab/StoryJS-Core).

```
{
  type: 'global',
  global: 'createStoryJS'
}

#### javascript

`javascript` executes a JavaScript function on the page and returns the result. If you want to stay simple it can just return `true` or `false`, but it can also send back additional information, e.g. `{ version: '3.4.0' }`, which will be saved by Hardboiled. A more intense example can be seen in a fancy way of discovering jQuery, along with its version number:

```
{
  type: 'javascript',
  test:  function() {
    var keys = Object.keys(window);
    var val, key;

    for(var i=0;i<keys.length;i++) {
      key = keys[i]
      if(window[key] && window[key].fn && window[key].fn.jquery) {
        return { version: window[key].fn.jquery };
      }
    }
  }
}
```

It loops through all of the keys attached to `window`, seeing if any will return `.fn.jquery`, which is the jQuery version number.

#### sudo

`sudo` executes in Hardboiled space, not JavaScript page space. You have a function that's passed the `page` object, which you can use to loop through files, check contents, and basically tear apart every request looking for information. For example, objects stored on S3 return a header called `Server` with the value `AmazonS3`. Let's find them by going through every resource the page requested:

```
{
  type: 'sudo',
  test: function(page) {
    var resource;
    for(var i = 0; i < page.resources.length; i++) {
      resource = page.resources[i];
      for(var j = 0; j < resource.headers.length; j++) {
        if(resource.headers[j].name == "Server" && resource.headers[j].value === "AmazonS3") {
          return true;
        }
      }
    }
  }
}
```

## Engines

Hardboiled can use a few engines to interact with the web. Right now we've got [PhantomJS](http://phantomjs.org) and [jsdom](https://github.com/tmpvar/jsdom). Who wants to write one for Zombie?

### PhantomJS

[PhantomJS](http://phantomjs.org) is a "headless WebKit" - basically, an invisible web browser that you can control using code. We use it to simulate a browser visiting a web site, that way we can test the functioning of the site in a practical way (ie running JavaScript) instead of manually looking at all of the scripts.

#### Installing PhantomJS-resource_body

Unfortunately, PhantomJS doesn't allow you to look inside of the remote files you're downloading outside of the page itself. We want to look at the CSS, JS, images, and whatever else comes our way, so we need to install a special fork of PhantomJS! I'm sure there are plenty, but I went ahead and picked [this one](https://github.com/dparshin/phantomjs/tree/resource_body).

I've included a copy of the OSX binary under `lib` (hey, it works for me), but if that doesn't work you'll need to copy and [build it yourself](http://phantomjs.org/build.html). If you place phantom anywhere other than at /phantom/phantomjs you'll also need to pass an option about where to find PhantomJS.

### jsdom

jsdom is a much much much lighter-weight PhantomJS (although that's a bit of a stretch). Read more at [https://github.com/tmpvar/jsdom](https://github.com/tmpvar/jsdom).

#### Limitations

Stick with PhantomJS if you can!

## Etc

Hexes, curses and swear words can be directed to me at [https://twitter.com/dangerscarf](@dangerscarf).

## TODO

* Split engines/etc into multiple files
* Deal with errors
  * Clue-parsing
  * Site-pulling
  * Whatever else
* Finalize API
* Docs docs docs
* Fall in line with node code conventions (aka clean the hell out of code)
* Understand that blahblah-8f6ca9b17ae3eba1e30276eef0a16282cb651c78.css is really blahblah.css
* Pull a list of libraries supported so you don't have to browse through `/clues/`
* Parse/display version/etc info
* Figure out callback stuff
* Break out external engines for jsdom/phantom/etc
* Don't automatically download huge files (or maybe per-page max?)
* Have a limit of the number of resources downloaded
* Clear up offline version
* Organization of clues
* Flesh out jsdom limitations
* Testing
* Implement eval for jsdom for the sake of selectors/etc (and fix up jsdom in general)