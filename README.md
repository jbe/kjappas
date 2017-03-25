
# Kjappas

**HTML-as-JavaScript Snabbdom template syntax**

---

Kjappas is a template syntax for [Snabbdom](https://github.com/snabbdom/snabbdom), and an alternative to [`snabdom/h`](https://github.com/snabbdom/snabbdom#snabbdomh). It lets you write reactive HTML templates that are plain old JavaScript functions.

## Installation

`npm install --save kjappas`

## Code sample

```javascript
import {infest} from "kjappas";

infest(window);

function UserProfile(user, onClick) {
  return div(".UserProfile",
    {
      ".admin": user.isAdmin
    },
    h4(user.name),
    img({
      src: user.avatarUrl,
      style: {cursor: "pointer"},
      $click: => onClick(user)
    })
  );
}
```

## Documentation

### Importing tags (or infesting the global scope)

Kjappas provides functions for all of the official HTML tags:

```javascript
import {p, strong} from "kjappas";

function SampleView() {
  return p("This is just some ", strong("example code"));
}
```

However, some find it tedious to maintain lists of tag imports. So let's just add them all to the global scope:

```javascript
import {infest} from "kjappas";

infest(window);
```
This defines all of kjappas' tag helpers on the global window object, making them available everywhere. Depending on how your bundler packages code, you may have to make sure all of your calls to tag helpers are inside functions, to prevent "not defined" errors. But that's a good idea anyway.

### Using tags

The tag functions share some similarities with `snabbdom/h`, but are shorter and more flexible. Here are some examples:

```javascript
    div(firstChild, secondChild, ...)
    button({$click: myEventFunc}, "Click me")
    img({src: "./rhubarb.png"})
    img("#avatar.small", {src: "./avatar.png"})
    p(".gray", "I have gray class")
    p(".gray", {".active": isActive}, "A foo walks into a bar, and then a baz comes along")
```

The parameters must conform to this pattern:

    <optional selector>, <optional data>, zero or more children...

In other words, the following are all valid calls:

```javascript
div(children...)
div(data, children...)
div(selector, children...)
div(selector, data, children...)
```

#### Parameters

##### selector

The optional `selector` parameter is a css selector similar to the one in `snabbdom/h`, except that you obviously don't need to pass the tag name itself. Examples of valid values are `".highlighted"`, `"#item-32.disabled.collapsible"`. Note that you cannot use the selector for properties that may change! Even though it might seem to work at first, it will produce errors. Instead use the `.` or `class` helper described further down.

##### data

The optional `data` parameter accepts the same fields as `snabbdom/h`, along with some additional shorthands. The supported snabbdom-style object fields are `class`, `key`, `style`, `on`, `attrs` and `props`. However, there are more conventient shorthands:

```javascript
// instead of writing..
hr({
  class: {
    selected: isSelected
  }
})
// .. you can write..
hr({".selected": isSelected})
// which means the same.
```

- Instead of `on: {click: clickHandler}`, you can use `$click: clickHandler`
- Instead of `class: {selected: isSelected}`, you can use `".selected": isSelected`
- Instead of `attrs: {href: someUrl}`, you can use `"%href": someUrl`
- Instead of `props: {href: someUrl}`, you can simply use `href: someUrl`; in other words; props can just be passed directly

Here is the "translation" table from kjappas to snabbdom:

    .           class
    $           on
    %           attrs
    (no prefix) props

A more elaborate example:

```javascript
div("#index.pane"
  {
    ".isActive": isActive,
    "$click": => handleClick
  },
  p({style: {fontWeight: "bold"}})
)
```

##### children

The `children` property works similarly to `snabbdom/h`, except that you can pass several parameters instead of an array. The list of paramaters is flattened, which means it is okay to pass arrays as well. The following are all valid calls:

```javascript
div(childOne, childTwo)
div(childOne, [childTwo, childThree], childFour, [childFive])
// ..which is equivalent to..
div(childOne, childTwo, childThree, childFour, childFive)
```

The children can be any valid snabbdom tree, incluing plain strings, or trees created using kjappas, `snabbdom/h`, or something else.

### Exported helper functions

##### tagNames

This is actually not a function, but an array of all the tag names that kjappas exports helpers for. You're not likely to ever need this, unless you're a l33t h4x0r.

##### defineTag(tag)

Given a tag name, `defineTag` returns a kjappas tag function for that tag. For example `const line = defineTag("line")`.

##### tagMod(tagFunc, modFunc)

This is experimental, and i'm not sure if it's a good idea. Given a kjappas tag function, or a string naming one of the standard HTML tags, and a modifier function, `tagMod` returns a new tag function that works the same as the original, except for applying `modFunc` on the result before returning it. This can be used to create tag helpers with slightly modified behaviour. Take the `Link` helper as an example:

```javascript
const Link = tagMod "a", (tag) ->
  tag.data.props.href or= "#"
  tag.data.on.click = defaultPrevented(t.data.on.click)
```

##### defaultPrevented(eventHandlerFunc)

Given an event handler function, returns another event handler, which in addition to calling the input event handler, also calls `event.preventDefault()`. This is useful for stuff like the example above.

##### createRefresh(templateFunc, domNode)

Given a root template function and a dom node, returns a refresh function. This refresh function can be called to draw the template into the mount point using snabbdom. The update will be debounced using a timout of 0, so that only the last update caused during an event response actually gets drawn. Any parameters passed to the refresh function will be forwarded to the template function. A simple example:

```javascript
function Greeter(name) {
  return p("Hello ", name);
}

const refresh = createRefresh(Greeter, document.getElementById("app"));

refresh("Joe");
refresh("Bob"); // Only this update will actually be flushed to the dom.
// However, updates during later events will flush just fine
```

The refresh function is designed to be easy to integrate with reactive state containers by simply subscribing it (my own Immux container in particular, although any container will work).

### Exported view components

There are also a few included view components:

##### Link

Works the same as the `a` tag, except that the `href` prop will default to `#`, and any passed `click` handler will be automatically default prevented. Actually, this is the only included component for now.
