Q = require 'q'
phantom = require 'phantom'
jsdom = require 'jsdom'
path = require 'path'

Engines = {}

class Engines.Template
    constructor: (page, options) ->
        @page = page
        @wait = options.wait || 1000
        @binary = options.binary || 'phantomjs' #path.join(__dirname, '/../phantom/phantomjs')

    openPage: () ->
        console.log("NOT IMPLEMENTED")

    closePage: () ->
        console.log("NOT IMPLEMENTED")

    evaluate: () ->
        console.log("NOT IMPLEMENTED")

    evaluate_with_args: (arg1) ->
        console.log("NOT IMPLEMENTED")

class Engines.PhantomJS extends Engines.Template

    openPage: () ->
        d = Q.defer()
        phantom.create { binary: @binary }, (ph) =>
            @ph = ph
            ph.createPage (page) =>
                @phPage = page
                @phPage.set 'onResourceReceived', (response) =>
                    # Let's only pull the response at the very final state
                    if response.status == 200 and response.stage == 'end'
                        @page.addResource(response)
                @phPage.open @page.url, (status) =>
                    # Let's wait for a bit after opening the page to try to do anything
                    setTimeout () =>
                        # ....clean this up!
                        this
                            .pullMeta()
                            .then (meta) =>
                                items = JSON.parse(meta)
                                for item in items
                                    @page.addMeta(item)
                                this.pullBody()
                                .then (body) =>
                                    @page.body = body
                                    d.resolve()
                    , @wait
        d.promise

    pullBody: () ->
        console.log('pulling body')
        this.evaluate ->
            document.body.innerHTML
        
    pullMeta: () ->
        this.evaluate ->
            meta_tags = document.getElementsByTagName('meta')
            meta = []
            for tag in meta_tags
                meta_object = {}
                for attr in tag.attributes
                    meta_object[attr.nodeName] = attr.nodeValue;
                meta.push meta_object
            JSON.stringify(meta)
        
    evaluate: (fn) ->
        d = Q.defer()
        @phPage.evaluate fn, (result) ->
            d.resolve(result)
        d.promise

    evaluate_with_args: (fn, arg1) ->
        d = Q.defer()
        @phPage.evaluate fn, (result) ->
            d.resolve(result)
        , arg1
        d.promise

    closePage: () ->
        @ph.exit()

class Engines.jsdom extends Engines.Template
    openPage: () ->
        d = Q.defer()
        @jsdom = jsdom.jsdom(@body)
        @window = @jsdom.parentWindow
        options = 
            FetchExternalResources: []
            ProcessExternalResources: false
            done: (err, window) => 
                # Find remote JavaScript
                scripts = window.document.getElementsByTagName('script')
                for script in scripts
                    if !!script.src
                        @page.addResource url: script.src

                @page.setBody window.document.body.innerHTML
                # Find remote stylesheets
                links = window.document.getElementsByTagName('link')
                for link in links
                    if !!link.href
                        @page.addResource url: link.href

                meta = window.document.getElementsByTagName('meta')
                for tag in meta
                    meta_object = {}
                    for i in tag.attributes
                        meta_object[tag.attributes[i].nodeName] = tag.attributes[i].nodeValue;
                    @page.addMeta(meta_object)
                    
                d.resolve()

        if @page.body
            options.html = @body
        if @page.url
            options.url = @url

        jsdom.env options
        d.promise

    closePage: () ->
        return

    evaluate: () ->
        d = Q.defer()
        d.resolve(false)
        d.promise

    evaluate_with_args: () ->
        d = Q.defer()
        d.resolve(false)
        d.promise

module.exports = Engines