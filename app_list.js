function findAlternativeEl() {
  if (!document.querySelectorAll) {
    return []
  }
  var els = document.querySelectorAll('div.card-content[data-docid]');
  if (els.length > 0 ) {
    var results = []
    for (var i = 0; i < els.length; i++) {
      var el = els[i]
      let anchors = el.querySelectorAll("a[href^='/store/apps/details?id=']")
      if (anchors.length > 0) {
        var appID = el.getAttribute('data-docid')
        results.push({id: appID, el: el})
      }
    }
    return results
  }
  els = document.querySelectorAll("a.AnjTGd[href^='/store/apps/details?id=']");
  if (els.length > 0) {
    var results = []
    for (var i = 0; i < els.length; i++) {
      var el = els[i]
      var appID = el.getAttribute('href').substring('/store/apps/details?id='.length)
      results.push({id: appID, el: el.parentNode})  
    }
    return results
  }
  return []
}
var list = ""
var apps = findAlternativeEl()
for(app in apps){list += apps[app].id + "<br>"}
document.body.innerHTML = list