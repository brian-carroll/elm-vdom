const elmLangContainer = document.getElementById('elm-lang-vdom');
const vdomContainer = document.getElementById('brian-vdom');

const elmApp = Elm.Main.embed(elmLangContainer, vdomContainer);
elmApp.ports.vdomOutput.subscribe(applyPatches);

function applyPatches(patches) {
  patches.forEach(patch => {
    switch (patch.type) {
      case 'AppendChild': {
        appendVnode(patch.parentDom, patch.vnode);
        break;
      }
      case 'InsertBefore': {
        const newNode = createNode(patch.vnode);
        const referenceNode = patch.dom;
        const parentNode = referenceNode.parentNode;
        parentNode.insertBefore(newNode, referenceNode);
        break;
      }
      case 'Remove': {
        patch.dom.remove();
        break;
      }
      case 'SetProp': {
        patch.dom[patch.key] = patch.value;
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
