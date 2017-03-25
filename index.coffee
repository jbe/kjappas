
snabbdom = require "snabbdom"
sdClass  = require("snabbdom/modules/class").default
sdProps  = require("snabbdom/modules/props").default
sdAttrs  = require("snabbdom/modules/attributes").default
sdStyle  = require("snabbdom/modules/style").default
sdEvents = require("snabbdom/modules/eventlisteners").default
h        = require('snabbdom/h').default

isValidSnabbdomChild = (x) ->
  ((typeof x == "string") or
    (typeof x == "object" and
      x.hasOwnProperty("sel") and
        x.hasOwnProperty("elm")))

looksLikeSelector = (x) ->
  typeof x == "string" and (x[0] == "." || x[0] == "#")

# parse selector, data and children to produce some snabb dom
helper = (selector, data, children) ->
  newData =
    class: {}
    on: {}
    attrs: {}
    props: {}
    hook: {}

  for own k, v of data
    switch k
      when "selector" then selector += v
      when "class", "key", "style", "on", "attrs", "props", "hook"
        newData[k] = v
      else switch k[0]
        when "$" then newData.on[   k.slice(1)] = v
        when "%" then newData.attrs[k.slice(1)] = v
        when "." then newData.class[k.slice(1)] = v
        when "_" then newData.hook[k.slice(1)] = v
        else newData.props[k] = v

  h selector, newData, children

# define the kjappas tag function for a given tag
defineTag = module.exports.defineTag = (tag) ->
  (args...) ->
    switch args.length
      when 0 then return h tag
      when 1
        return h tag + args[0] if looksLikeSelector args[0]      # selector
        return h tag, {}, args if isValidSnabbdomChild args[0]   # child
        return helper tag, args[0] if typeof args[0] == "object" # data
        console.log.apply args
        throw new Error "invalid single kjappas tag argument"

    # now the first arg must be either a selector or data.
    # the second is either data or a child.

    sel = tag
    sel += args.shift() if looksLikeSelector args[0]
    params = args.shift() if typeof args[0] == "object"

    helper sel, params, [].concat.apply([], args)

tagNames = module.exports.tagNames = "a abbr address article aside audio b bdi bdo blockquote button canvas caption cite code colgroup datalist dd del details dfn div dl dt em fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 header hgroup i iframe ins kbd label legend li mark menu meter nav noscript object ol optgroup option output p pre progress q rp rt ruby s samp script section select small span strong style sub summary sup table tbody td textarea tfoot th thead time title tr u ul video applet acronym bgsound dir frameset noframes isindex area base br col command embed hr img input keygen link meta param source track wbr basefont frame applet acronym bgsound dir frameset noframes isindex listing nextid noembed plaintext rb strike xmp big blink center font marquee multicol nobr spacer tt basefont frame main map".split(" ")

tags = {}
module.exports = {tags}
module.exports[t] = tags[t] = defineTag(t) for t in tagNames

tagMod = module.exports.tagMod = (tagFunc, modFunc) -> ->
  if typeof tagFunc == "string"
    tagFunc = tags[tagFunc]
  r = tagFunc.apply(this, arguments)
  modFunc(r)
  r

# returns a function that will be deferred until after the call stack
# has finished. If it is called again before that, only the last call
# will be "remembered". This is used to optimize redraws so that they
# only happen once, after all mutations of a batch have finished.
debounceZero = (fn) ->
  timeout = null
  cb = ->
    args = arguments
    clearTimeout(timeout)
    tieout = setTimeout (-> fn(args...)), 0

# create a refresh function (see docs)
module.exports.createRefresh = (fn, vnode, patch) ->
  patch ||= snabbdom.init([sdClass, sdProps, sdAttrs, sdStyle, sdEvents])

  debounceZero (args...) ->
    vnode = patch vnode, fn(args...)

defaultPrevented = module.exports.defaultPrevented = (fn, args...) ->
  return fn if !fn
  (ev) ->
    ev.preventDefault()
    fn(ev, args...)

module.exports.infest = (obj=window) ->
  for own k, v of tags
    obj[k] = v if k != "map"


# Included utility components

Link = module.exports.Link = tagMod "a", (t) ->
    t.data.props.href or= "#"
    t.data.on.click = defaultPrevented(t.data.on.click)

Button = module.exports.Button = (props) ->
    text = props.value
    delete props.value
    button props, text
