const elmLangContainer = document.getElementById('elm-lang-vdom');
const vdomContainer = document.getElementById('brian-vdom');

const elmApp = Elm.Main.embed(elmLangContainer);
elmApp.ports.vdomOutput.subscribe(traverse(vdomContainer));

function traverse(domNode) {
  console.log('_____________________________________________\n');
  console.log('traverse', domNode);
  return function applyPatchTree(patchTree) {
    console.log('applyPatchTree', patchTree);
    const { patches, recurse } = patchTree;

    applyPatches(domNode, patches);

    for (const idx in recurse) {
      const childDom = domNode.childNodes[idx];
      const childPatchTree = recurse[idx];
      traverse(childDom)(childPatchTree);
    }
  };
}

function applyPatches(dom, patches) {
  console.log('applyPatches', dom);
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
        const kids = dom.childNodes;
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
    if (vnode.childNodes) {
      vnode.childNodes.forEach(childVnode => appendVnode(elem, childVnode));
    }
    return elem;
  }
}

function appendVnode(parentDom, vnode) {
  const newDomNode = createNode(vnode);
  parentDom.appendChild(newDomNode);
}
