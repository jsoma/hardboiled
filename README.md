# Hardboiled!

**Hardboiled** is a detective kit for investigating **how web sites are built.** It runs JavaScript, scrapes stylesheets, and isn't afraid to **break a few bones** to get the job done. It tracks down frameworks, jQuery plugins, grid systems, and anything else your dark heart desires.

*Hardboiled is a work-in-progress like crazy. I've never written node anything before, and it's really just up so I can hassle folks for feedback. The ever-so-convenient web app is on its way.*

## Introduction

Hardboiled goes a little something like this

```js
hardboiled = require('hardboiled')

// When you scan, you get back a Hardboiled.Page object that can do all sorts of stuff. These are the basics you're looking for.
hardboiled.scan("http://handsomeatlas.com", function(err, page) {
  console.log(page.url)
  // http://handsomeatlas.com

  console.log(page.matches)
  // [
  //   { title: 'Google Analytics',
  //     description: undefined,
  //     url: 'http://www.google.com/analytics' },
  //   { title: 'Twitter Bootstrap, Responsive CSS',
  //     description: 'Prior to Bootstrap 3, you could enable responsive design by adding in an additional stylesheet.',
  //     url: 'http://getbootstrap.com' },
  //   { title: 'jQuery',
  //     description: undefined,
  //     url: 'http://jquery.com' },
  //   { title: 'Facebook Like button',
  //     description: undefined,
  //     url: undefined }
  //  ]
})
```

## How it works

**Hardboiled** is based on two things, a **headless browser** and **clue files**.

A **headless browser** like [PhantomJS](http://phantomjs.org).

**Clue files** are JSON-y files describing different technologies. They live (or will live) cluttered in various subdirectories in `/clues/`, although you can specify other directories if you'd like.

We can only detect as many technologies as we have clues for, so please be a hero and contribute wicked-awesome clues.

## Installation

You'll need to download PhantomJS from [http://phantomjs.org/download.html](http://phantomjs.org/download.html), and stick it somewhere in your path.

Hardboiled is also not yet in npm, so you'll want to snag it via `npm install ssh+https://github.com/jsoma/hardboiled`

## Clues

*Generate clues in a friendly way over at [http://jsoma.github.io/hardboiled/generator.html](http://jsoma.github.io/hardboiled/generator.html)*

Hardboiled depends on user-submitted clues to decipher the web. Each clue file describes the technology that's being looked for and includes the tests needed to figure out if the page is using the technology.

```js
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

### Technology Info

The technology can be described using a `title`, `description`, `url`, and comma-delimited `tags`. The technology is tested using an array of `tests`.

Tags covering a category should be kept plural (e.g. **frameworks** not **framework**).

### Test info

Well those are pretty complicated, let's make a whole section about them.

## Test types

Tests each have a `type` and a `test`.

Types of tests are [`filename`](#filename), [`selector`](#selector), [`global`](#global), [`javascript`](#sudo), [`sudo`](#sudo), [`header`](#header), [`jquery`](#jquery) and [`meta`](#meta).

#### filename

```js
{
  type: 'filename',
  test: 'bootstrap-responsive'
}
```

`filename` looks for JavaScript or stylesheet files with a given name. It also does some normalization and stripping, so 'bootstrap-reponsive' will match 'bootstrap-responsive.min.css'.

`filename` is the easiest (and least effective) type of test, but it's a pretty good start. Send a pull and later on maybe someone will upgrade it to something a bit fancier? Check out the jQuery example under `javascript` to see what kind of improvements that could be made beyond looking for a file named `jquery.js`.

#### selector

```js
{
  type: 'selector', 
  test: 'iframe[src^="http://embed.verite.co/timeline"]'
}
```

`selector` looks for an element on the page. This example looks for the embedded version of [TimelineJS](http://timeline.knightlab.com), an iframe beginning with `http://embed.verite.co/timeline`.

#### global

```js
{
  type: 'global',
  test: 'createStoryJS'
}
```

`global` checks if a variable/function/etc with that name exists off of the `window` object on the page. You could naively look for jQuery by trying to find '$', but this example looks for [TimelineJS](http://timeline.knightlab.com)/[StoryJS](https://github.com/NUKnightLab/StoryJS-Core).

#### header

```js
{
  type: 'header',
  test: { 'Server': 'AmazonS3' }
}

{
  type: 'header',
  test: 'X-Varnish'
}
```

`header` attempts to find headers with the given name. Looks in fetched content, too, for the time being, although that should probably be a setting. If you don't care about the value of the header you can just pass a string, otherwise pass a hash.

#### jquery

```js
{
  type: 'jquery',
  test: 'isotope'
}
```

`jquery` tests if you can execute a given method on a jQuery node. It's an easy way to test for jQuery plugins!

This test looks for the tiling plugin [Isotope](http://isotope.metafizzy.co) by attempting (roughly) `$("<div></div>").isotope`. There can probably be a conflict if there are multiple instances of jQuery living on the same page, but hey, that's probably causing problems on the site anyway.

#### javascript

```js
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

`javascript` executes a JavaScript function on the page and returns the result. If you want to stay simple it can just return `true` or `false`, but it can also send back additional information, e.g. `{ version: '3.4.0' }`, which will be saved by Hardboiled.

This example is a fancy way of discovering jQuery, along with its version number. It loops through all of the keys attached to `window`, seeing if any will return `.fn.jquery`, which is the jQuery version number.

#### sudo

```js
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

`sudo` executes in Hardboiled space, not JavaScript page space. You have a function that's passed the `page` object, which you can use to loop through files, check contents, and basically tear apart every request looking for information.

For example, objects stored on S3 return a header called `Server` with the value `AmazonS3`. We found them above by going through every resource the page requested (although now we'd just use `header`).

#### meta

```js
{
  type: 'meta',
  test: {
    name: 'generator',
    test: /\^Wordpress/
  }
}
```

`meta` looks for meta tags that match a given set of attributes. For example, if we wanted to see if a given blog was being served by WordPress.

This looks for a meta tag with the `name` attribute of `generator` and a `content` attribute that starts with `Wordpress`. You don't have to use regular expressions, but if you provide a string instead you need an exact match.

[Back to test types](#test-types)

## Engines

Hardboiled can use a few engines to interact with the web. Right now we've got [PhantomJS](http://phantomjs.org) and a partial implementation for [jsdom](https://github.com/tmpvar/jsdom). Who wants to write one for [Zombie](http://zombie.labnotes.org)?

### PhantomJS

[PhantomJS](http://phantomjs.org) is a "headless WebKit" - basically, an invisible web browser that you can control using code. We use it to simulate a browser visiting a web site, that way we can test the functioning of the site in a practical way (ie running JavaScript) instead of manually looking at all of the scripts. If you use [this fork](https://github.com/dparshin/phantomjs/tree/resource_body) you can actually look at the contents of the stylesheets and javascript.

### jsdom

jsdom is a much much much lighter-weight PhantomJS (although that might be a bit of a stretch). Read more at [https://github.com/tmpvar/jsdom](https://github.com/tmpvar/jsdom).

#### Limitations

Stick with PhantomJS if you can!

## Etc

Hexes, curses and swear words can be directed to me at [https://twitter.com/dangerscarf](@dangerscarf).

## TODO

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
* log all of the stuff that doesn't yet mean anything (js filenames, meta generator tags, etc)
* in fact, make the whole thing a page analysis instead of just page info. Hardboiled.Analysis!
* Figure out callback stuff
* Don't automatically download huge files (or maybe per-page max?)
* Have a limit of the number of resources downloaded
* Allow tests to be ANY or ALL
* Make header search only work for initial page
* Make header keep data on what triggered it
* Tests that map X site to Y tech, so you can run one at a time
* Organization of clues
* Flesh out jsdom limitations (or fill out jsdom engine abilities)
* Testing
* Implement eval for jsdom for the sake of selectors/etc (and fix up jsdom in general)