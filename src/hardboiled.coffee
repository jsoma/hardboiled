Q = require 'q'
fs = require 'fs'
urlparser = require 'url'
request = require 'request'
vm = require 'vm'
jsdom = require 'jsdom'
path = require 'path'
dir = require 'node-dir'
_ = require 'underscore'

Hardboiled = {};

Hardboiled.Engines = require './engines'

class Hardboiled.Clue
    constructor: (options) ->
        @path = options.path
        if @path
            content = fs.readFileSync(@path, 'utf8')
            sandbox = {}
            vm.runInNewContext('var data = ' + content, sandbox)
            data = sandbox.data
        
        _.extend(this, options.data || data)
        @data = options.data || data
    
    toMatch: () =>
        title: @data.title
        description: @data.description
        url: @data.url
        
    runTests: (page) =>
        Q.all @tests.map (test) => 
            this['test_' + test.type].call(this, page, test.test)

    processResult: (type, result) =>
        # This used to do more but now maybe it should just return something for the promise
        response = {
            type: type,
            # If we're returned false or an empty array, no dice!
            passed: !!result && !(result instanceof Array && result.length == 0)
        }
        # Sometimes we pass the content matched instead of true/false
        if result != !!result
            if result instanceof Array
                response.data = { matches: result }
            else
                response.data = result
        response

    test_meta: (page, data) =>
        this.runTest data, (d) =>
            result = page.hasMeta(data)
            response = this.processResult 'meta', result
            d.resolve(response)

    test_header: (page, data) =>
        this.runTest data, (d) =>
            result = page.hasHeader(data)
            response = this.processResult 'header', result
            d.resolve(response)

    test_text: (page, text) =>
        this.runTest text, (d) =>
            result = page.hasText(text)
            response = this.processResult 'text', result
            d.resolve(response)

    test_domain: (page, regex) =>
        this.runTest regex, (d) =>
            results = regex.exec(urlparser.parse(page.url).hostname)
            response = this.processResult 'domain', !!results
            d.resolve(response)

    test_jquery: (page, method) =>
        this.runTest method, (d) =>
            promise = page.evaluate_with_args (method) =>
                # Have to find jQuery first before you can test a method
                keys = Object.keys(window)

                for key in keys
                    if(!!window[key] && !!window[key].fn && !!window[key].fn.jquery)
                        foundjQuery = window[key]

                return if(!foundjQuery)
                !!foundjQuery("<div></div>")[method];
            , method
            
            Q(promise).then (value) =>
                response = this.processResult 'jquery', !!value
                d.resolve(response)

    test_filename: (page, filename) =>
        this.runTest filename, (d) =>
            results = page.resources
                .filter (resource) =>
                    resource.isNamed(filename)
                .map (resource) ->
                    resource.url
            response = this.processResult 'filename', results
            d.resolve(response)

    test_selector: (page, selector) ->
        this.runTest selector, (d) =>
            promise = page.evaluate_with_args (selector) ->
                return document.querySelector(selector) != null
            , selector
            Q(promise).then (value) =>
                response = this.processResult 'selector', !!value
                d.resolve(response)

    test_global: (page, global) =>
        this.runTest global, (d) =>
            promise = page.evaluate_with_args (variable) ->
                if(variable.indexOf('.') != -1)
                    variable.split('.').reduce (prev, curr) ->
                       return if !prev
                       return prev[curr]
                    , window
                else
                    return !!window[variable]
            , global
            Q(promise).then (result) =>
                response = this.processResult 'global', !!result
                d.resolve(response)

    test_sudo: (page, fn) =>
        this.runTest fn, (d) =>
            result = fn.call(this, page)
            response = this.processResult 'sudo', result
            d.resolve(response)

    test_javascript: (page, fn) =>
        this.runTest fn, (d) =>
            promise = page.evaluate fn
            Q(promise).then (result) =>
                response = this.processResult 'javascript', result
                d.resolve(response)        

    runTest: (test, fn) =>
        d = Q.defer()
        process.nextTick () =>
            if !test
                # Trying to run a test without an actual test value
                return d.resolve(false)
            fn(d)
        d.promise

class Hardboiled.Resource    
    constructor: (response) ->
        @url = response.url
        @body = response.body
        @headers = response.headers
        @path = urlparser.parse(@url).pathname
        url_pieces = @path.split('/')
        @filename = url_pieces[url_pieces.length - 1]
        # For god's sake fix those regular expressions up
        @cleaned_name = @filename.replace(/([-.](min|compressed))?(\.[a-z]*)?$/,'')
        @cleaned_url = @url.replace(/.(min|compressed)/,'')
        pieces = @filename.split('.')
        if pieces.length > 1
            @extension = pieces[pieces.length - 1]
        @type = this.findType()
        @comments = this.findComments()

    findType: () ->
        @extension

    findComments: () ->
        if !@body
            return []
        if @type == 'css'
            regex = new RegExp(/\/\*\*(.|\n)+?\*\//g)
            @body.match(@comment_regex) || []        
        else if @type == 'js'
            regex = new RegExp(/\/\*[^*]*\*+([^/*][^*]*\*+)*\//g)
            @body.match(@comment_regex) || []

    isNamed: (name) ->
        if name instanceof RegExp
            name.test(@cleaned_url)
        else if name.indexOf('/') != -1
            @cleaned_url.indexOf(name) != -1
        else
            name == @cleaned_name || name == @filename + '.' + @extension

class Hardboiled.Page
    constructor: (options) ->
        @url = options.url
        @body = options.body
        @resources = []
        @meta = []
        @matches = []
        @engine = new Hardboiled.Engines[options.engine || 'PhantomJS'](this, options)

    processClues: (clues) ->
        Q.all clues.map (clue) =>
            d = Q.defer()
            process.nextTick () =>
                clue.runTests(this)
                    .then (results) =>
                        passed = results.filter (result) -> result && result.passed
                        if passed.length > 0
                            match = clue.toMatch()
                            data = _.pluck(passed, 'data')
                            match.data = _.compact(data)
                            @matches.push match
                        d.resolve()
            d.promise

    addResource: (data) ->
        resource = new Hardboiled.Resource(data)
        @resources.push(resource)

    hasText: (text) ->
        @body.indexOf(text) != -1

    addMeta: (data) ->
        @meta.push(data)

    hasHeader: (data) ->
        # TODO need to aggregate all of the files this is true for
        results = []
        if typeof data != 'string'
            key = Object.keys(data)[0]
            value = data[key]
            for resource in @resources
                for header in resource.headers
                    if !!value.exec
                        value_match = header.value.match(value)
                    else
                        value_match = header.value == value
                    if header.name == key && value_match
                        results.push [ resource.url, header ]
        else # it's a string
            key = data
            for resource in @resources
                for header in resource.headers
                    if header.name == key
                        results.push [ resource.url, header ]
        if results.length > 0
            results
        else
            false

    hasMeta: (data) ->
        keys = Object.keys(data)
        @meta.filter (tag) =>
            # if Object.keys(tag).length != keys
            #     return false
            extras = []
            for key in keys
                if !tag[key]
                    return false 
                # Duck typing RegExp, instanceof won't work
                if !!data[key].exec
                    matches = tag[key].match(data[key])
                    if matches == null
                        return false 
                    # If there's anything captured by the regex, return it
                    if matches.length > 1
                        extras.push matches.slice(1)
                else
                    return false if tag[key] != data[key]
            extras.length > 0 ? extras : true

    evaluate_with_args: (fn, arg1) ->
        @engine.evaluate_with_args(fn, arg1)

    evaluate: (fn) ->
        @engine.evaluate(fn)

    openPage: () ->
        @engine.openPage()

    closePage: () ->
        @engine.closePage()

class Hardboiled.Scanner
    constructor: (options) ->
        @path = options.path || '../clues'

    importClues: (callback) ->
        @clues = []
        dir.files path.resolve(__dirname, @path), (err, files) =>
            for file in files
                continue unless /\.js$/.test file
                clue = new Hardboiled.Clue(path: file)
                @clues.push clue
            callback(this)

    scan: (options, callback) ->
        # Clues haven't been added yet? Let's initialize that and come back later.
        if !@clues
            return this.importClues () =>
                this.scan(options, callback)

        page = new Hardboiled.Page(options)
        
        page.openPage()
        .then () =>
            page.processClues(@clues)
        .then () =>
            page.closePage()
            callback(null, page)

Hardboiled.scan = (url, callback) ->
    scanner = new Hardboiled.Scanner({})
    scanner.scan(url: url, callback)

module.exports = Hardboiled