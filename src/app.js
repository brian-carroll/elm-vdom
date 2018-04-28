const elmLangContainer = document.getElementById('elm-lang-vdom');
const vdomContainer = document.getElementById('brian-vdom');

const elmApp = Elm.Main.embed(elmLangContainer);
elmApp.ports.vdomOutput.subscribe(traverse(vdomContainer));

function traverse(domNode) {
  return function applyPatchTree(patchTree) {
    console.log('patch tree: ', patchTree);
    const { patches, recurse } = patchTree;

    applyPatches(domNode, patches);

    for (const idx in recurse) {
      const childDom = domNode.children[idx];
      const childPatchTree = recurse[idx];
      traverse(childDom)(childPatchTree);
    }
  };
}

function applyPatches(dom, patches) {
  console.log('_____________________________________________');
  console.log('Applying patches to DOM node: ', dom);
  patches.forEach(patch => {
    console.log(patch);
    switch (patch.type) {
      case 'AppendChild': {
        appendVnode(dom, patch.vnode);
        break;
      }
      case 'Replace': {
        const newNode = createNode(patch.vnode);
        dom.parentNode.replaceChild(newNode, dom);
        break;
      }
      case 'RemoveChildren': {
        const kids = dom.children;
        for (let i = 0; i < patch.number; i++) {
          kids[kids.length - 1].remove();
        }
        break;
      }
      case 'SetProp': {
        dom[patch.key] = patch.value;
        break;
      }
      case 'RemoveAttr': {
        dom.removeAttribute(patch.key);
        break;
      }
      default:
        throw new Error('Unknown patch type ' + patch.type);
    }
  });
}

function createNode(vnode) {
  if (vnode.tagName === 'TEXT') {
    return document.createTextNode(vnode.text);
  } else {
    const elem = document.createElement(vnode.tagName);
    const props = vnode.props;
    for (key in props) {
      elem[key] = props[key];
    }
    if (vnode.children) {
      vnode.children.forEach(childVnode => appendVnode(elem, childVnode));
    }
    return elem;
  }
}

function appendVnode(parentDom, vnode) {
  const newDomNode = createNode(vnode);
  parentDom.appendChild(newDomNode);
}
