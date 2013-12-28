var hardboiled = require('../lib/hardboiled');
var path = require('path');
var _ = require('underscore');

var scanner = new hardboiled.Scanner({});

lines = []

lines.push("# Hardboiled Clues")

lines.push("These are all of the technologies that Hardboiled can detect. This list is automatically generated from the `clues` directory.")

CLUEROOT = path.join(__dirname, '../clues')
scanner.importClues( function(err) {
  _.sortBy(scanner.clues, function(clue) { 
      return clue.title.toLowerCase();
  } )
  .forEach( function(clue) {
    lines.push("");
    lines.push('## ' + clue.title);
    if(clue.url) {
      lines.push("[" + clue.url + "](" + clue.url + ")");
    }
    lines.push("Found at: " + path.relative(CLUEROOT, clue.path));
    lines.push(clue.description || "Needs description");
    if(clue.tags) {
      lines.push("Tagged with: " + clue.tags);
    }
    lines.push("Test types: " + clue.tests.map( function(test) { return test.type } ).join(", "));
  });
  console.log(lines.join("\n"));
});