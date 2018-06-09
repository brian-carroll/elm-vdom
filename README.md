Virtual DOM implemented (mostly) in Elm
=======================================

A virtual DOM library using as little JavaScript as possible and as much Elm as possible. "Patch" values are generated in Elm, then sent to JavaScript to be applied.

In particular I want to avoid manipulating JavaScript references in Elm as much as possible. I'm interested in the idea of Elm being compiled to WebAssembly in the future, and WebAssembly currently can't deal with DOM references. This made me curious to see how much of a Virtual DOM could be built without actual DOM references.

I ended up with the patches being organised into a _tree_ structure instead of a list. The JavaScript patching logic traverses that tree from the root DOM node, and may or may not apply a patch at each step.

There's some overhead in using this patch tree data structure. In order to update a deeply nested DOM node, we first have to traverse to it all the way from the root. But in most cases that overhead should be small compared to the DOM manipulation itself.



Next steps: Events
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
    - ID's are ever-increasing Int's. Wrap around at maxint. Mod or summat.
    - Stick the ID onto the handler function object.
- Idea
    - Put handler ID in the vdom node
    - Next time we update that handler, pick up its old handler ID out of the old vdom, and put a new ID in the new vdom
    - Patch contains old and new IDs
        - Maybe oldId never existed (adding an event handler)
        - Maybe newId doesn't exist (removing an event handler)
        - Suggests some dedicated Event patch types
    - Make sure the top patch tree node has the _full_ list of all handlers underneath it
    - Pluck the handler list offa the top patch tree node
    - Fold over that shit
    - Sequence of ops to avoid missing events
        - Put new handlers into the state
        - Update the DOM
        - Take old handlers off the state (JS will need to send back the list of IDs to delete)
