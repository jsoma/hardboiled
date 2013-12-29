var hardboiled = require('../lib/hardboiled');
var path = require('path');
var _ = require('underscore');

var scanner = new hardboiled.Scanner({});

lines = []

lines.push("# Hardboiled Clues")

lines.push("These are all of the technologies that Hardboiled can detect. This list is automatically generated from the `clues` directory.")

CLUEROOT = path.join(__dirname, '../clues')
scanner.importClues( function(err) {
  
  lines.push("Hardboiled currently supports " + scanner.clues.length + " different clues.");
  _.sortBy(scanner.clues, function(clue) { 
      return clue.title.toLowerCase();
  } )
  .forEach( function(clue) {
    lines.push('### ' + clue.title);

    if(clue.url)
      lines[lines.length-1] = lines[lines.length-1] + " [" + clue.url + "](" + clue.url + ")";

    if(clue.description)
      lines.push(clue.description);

    file_path = path.relative(CLUEROOT, clue.path)

    lines.push("Tagged with: " + (!clue.tags ? "none" : clue.tags) +
      " | Test types: " + clue.tests.map( function(test) { return test.type } ).join(", ") +
      " | " + "Found at: [" + file_path + "](" + "https://github.com/jsoma/hardboiled/blob/master/clues/" + file_path + ")");
  });
  console.log(lines.join("\n\n"));
});