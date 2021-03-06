function getTextNodesIn(node, includeWhitespaceNodes) {
 var textNodes = [], nonWhitespaceMatcher = /\S/;

 function getTextNodes(node) {
   if (node.nodeType == 3) {
     if (includeWhitespaceNodes || nonWhitespaceMatcher.test(node.nodeValue)) {
       textNodes.push(node);
     }
   } else {
     for (var i = 0, len = node.childNodes.length; i < len; ++i) {
       getTextNodes(node.childNodes[i]);
     }
   }
 }

 getTextNodes(node);
 return textNodes;
}

function isUpper(l) {
  return l == l.toUpperCase() && l != l.toLowerCase();
}

var n = getTextNodesIn(document);

for(i = 0; i < n.length; i++) {
  var words = n[i].data.split(" ");
  for(j = 0; j < words.length; j++) {
    var w = words[j];
    hom_for_word = homonyms[w.toLowerCase()];
    if (hom_for_word != undefined) {
      var hom;
      if (hom_for_word.length > 1) {
        hom = hom_for_word[Math.floor(Math.random() * hom_for_word.length)];
      } else {
        hom = hom_for_word[0];
      }
      if (isUpper(w[0])) {
        hom = hom.charAt(0).toUpperCase() + hom.slice(1);
      }
      words[j] = hom;
    }
  }
  n[i].data = words.join(" ");
}
