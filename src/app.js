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
        const danglingElement = createElemFromVnode(patch.vnode);
        patch.dom.insertBefore(danglingElement);
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

function createElemFromVnode(vnode) {
  if (vnode.tagName === 'TEXT') {
    return document.createTextNode(vnode.text);
  } else {
    const elem = document.createElement(vnode.tagName);
    vnode.props.forEach(prop => {
      elem[prop.key] = prop.value;
    });
    if (vnode.children) {
      vnode.children.forEach(childVnode => appendVnode(elem, childVnode));
    }
    return elem;
  }
}

function appendVnode(parentDom, vnode) {
  const newDomNode = createElemFromVnode(vnode);
  parentDom.appendChild(newDomNode);
}
