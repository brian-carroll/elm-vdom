Virtual DOM implemented (mostly) in Elm
=======================================

As much as possible of code in Elm except for the final DOM mutation, which is done using ports.



Algorithm
---------

### Description
- Use separate HTML and vdom 'libraries', as in Elm std lib
- HTML library produces a virtual DOM tree
- Vdom diff keeps track of 3 trees
    - old vdom
    - new vdom
    - real DOM
- Old vdom and real DOM are assumed to be similar
- Using old vdom for traversal makes for easier code than traversing real DOM directly, but we use real DOM references so that we know where to apply the patches.
- Outputs a list of patches (containing real DOM references)

### Comments
- Need 3 trees
    - Can't have real DOM references inside of the 'old vdom' tree
    - Because at the time we are creating new vdom nodes, we have not yet created the corresponding real DOM nodes
- Traversing the real DOM requires some dirty tricks with `Json.Decode` to track JS object references in Elm.
- Later I want to do another project to compile this to Wasm, which wouldn't be able to traverse the DOM like this.



Alternative algorithms
----------------------

### Output patches in a tree rather than a list
- Traverse this tree in JS, applying the patches as you go
- No need for any JS references in Elm
- Tree may contain some empty 'parent patches', which don't do anything except contain 'child patches'
- Should be possible to prune empty branches from the patch tree, on the way back up the recursion stack
- Maybe patches can use a child index to skip irrelevant child nodes (tricky if adding/removing)
- Can we encode the patch tree to JSON as we do the recursion in the diff algorithm?

### Combine the HTML and vdom libraries into one?
- Maybe there are too many traversals going on
    1. 'Traversal' of the view functions to build a vdom tree
    2. Traverse the vdom trees to create patches
    3. Traverse the patches in JS to apply them (smaller tree though)
- Maybe we could reduce this down to 2
    1. View function produces a set of patches directly
    2. JS traverses the patches
- The HTML lib would have to be monadic, I think, because it is has a 'hidden' state - the previous tree. Would that make the API nasty?
- This is probably trying to solve a problem that doesn't exist, since the tree of patches is not really much different from a list/array of patches.
```elm
    div [ attr1 "stuff" ]
        [ p [] [ text "things" ]
        ]
```
- I don't think this idea will work with anything like the current API
- Problem is that the first 'traversal', which I put in quotes, is done by the _runtime_, not by my code!
