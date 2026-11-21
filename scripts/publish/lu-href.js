// Maps a showcase route ("/c/button?x=1#y") to its static file, relative to the site root.
// Shared by the exporter (node, vm) and by the pages (inlined in <head>), so both agree.
// `root` is "" for pages at the top level and "../" for c/, full/ and t/.
function luHref(path, root) {
  var m = /^([^?#]*)([?#].*)?$/.exec(path), p = m[1], rest = m[2] || "", f = null, x;
  if (p === "/") f = "index.html";
  else if ((x = /^\/(c|full)\/([^/]+)$/.exec(p))) f = x[1] + "/" + x[2] + ".html";
  else if ((x = /^\/templates\/([^/]+)$/.exec(p))) f = "t/" + x[1] + ".html";
  else if ((x = /^\/([a-z]+)$/.exec(p))) f = x[1] + ".html";
  return f === null ? null : root + f + rest;
}
