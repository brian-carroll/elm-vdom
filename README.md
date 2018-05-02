Virtual DOM implemented (mostly) in Elm
=======================================

As much as possible of code in Elm except for the final DOM mutation, which is done using ports.



Algorithm
---------

### Description
- Use separate HTML and vdom 'libraries', as in Elm std lib
- HTML library produces a virtual DOM tree
- vdom produces a _tree_ of patches (rather than a list)
- JS traverses the patch tree, applying patches
- No JS references at all on Elm side
    - all done through ports
- Slightly more traversing required compared to an array. But you don't have to convert a list to an array either


Events
------
- Need `onClick` and friends
- Modify stdlib implementation
    - New datatype `Facts` to cover attributes, properties, events and styles
- Modify `applyEvents` from stdlib VirtualDom.js
- Decoders? I think they're plain values with no functions in them. Could maybe pass them through ports but not sure.
- May have to put handler functions in the Model state
- Could impose restriction for handlers to always handle one input value, which could be `undefined`. Then it breaks if you don't use `success`, which is good.

- Handler function
    - Elm `on : String -> Decoder msg -> Attribute msg`
        - Decoder receives the event object
    - JS `addEventListener(key, handler)`
    - When the event triggers, we send an object to an Elm port
        - Some ID to identify what function will handle it
            - Index into a Dict
            - List of tree indexes? That only identifies the Vdom node. But we can have many listeners per node.
        - The event object