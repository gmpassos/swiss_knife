
import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'dart:js_util';

Element createDiv([bool inline = false, String html]) {
  var div = new Element.div() ;

  if (inline) div.style.display = 'inline-block';

  if (html != null) {
    setElementInnerHTML(div, html);
  }

  return div ;
}

Element createDivInline([String html]) {
  return createDiv(true, html);
}

const _HTML_ELEMENTS_ALLOWED_ATTRS = ['style', 'src', 'field', 'navigate', 'action', 'capture', 'oneventkeypress'] ;

AnyUriPolicy _anyUriPolicy = new AnyUriPolicy() ;

class AnyUriPolicy implements UriPolicy {
  @override
  bool allowsUri(String uri) {
    return true ;
  }
}

NodeValidatorBuilder _nodeValidatorBuilder = new NodeValidatorBuilder()
  ..allowTextElements()
  ..allowHtml5()
  ..allowElement("div", attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
  ..allowElement("span", attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
  ..allowElement("img", attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
  ..allowElement("textarea", attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
  ..allowElement("input", attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
  ..allowElement("button", attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
  ..allowElement("iframe", attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
  ..allowImages(_anyUriPolicy)
  ..allowInlineStyles()
;

void setElementInnerHTML(Element e, String html) {
  e.setInnerHtml(html, validator: _nodeValidatorBuilder) ;
}

void appendElementInnerHTML(Element e, String html) {
  e.appendHtml(html, validator: _nodeValidatorBuilder) ;
}

void scrollToTopAsync(int delayMs) {
  if (delayMs < 1) delayMs = 1 ;
  new Future.delayed( new Duration(milliseconds: delayMs), scrollToTop) ;
}

void scrollToTop() {
  window.scrollTo(window.scrollX,0, {'behavior': 'smooth'});
}

void scrollToBottom() {
  window.scrollTo(window.scrollX, document.body.scrollHeight, {'behavior': 'smooth'});
}

void scrollToLeft() {
  window.scrollTo(0, window.scrollY, {'behavior': 'smooth'});
}

void scrollToRight() {
  window.scrollTo(document.body.scrollWidth, window.scrollY, {'behavior': 'smooth'});
}

Map<String,bool> _addedJScripts = {} ;

bool addJScript(String scriptCode) {
  if ( _addedJScripts.containsKey(scriptCode) ) return false ;
  _addedJScripts[scriptCode] = true ;

  /*
  print("addJScript: <<<");
  print(scriptCode) ;
  print(">>>") ;
  */

  HeadElement head = querySelector('head') ;
  ScriptElement script = new ScriptElement() ;
  script.type = "text/javascript";
  script.text = scriptCode ;
  head.children.add(script);

  return true ;
}

typedef void MappedFunction(dynamic o) ;

void mapJSFunction(String jsFunctionName, MappedFunction f) {

  String setterName = "__mapJSFunction__set_$jsFunctionName" ;

  String scriptCode = '''
  
    $jsFunctionName = function(o) {};
  
    function $setterName(f) {
      console.log('mapJSFunction: $jsFunctionName(o)');
      $jsFunctionName = f ;
    }
    
  ''';
  
  addJScript(scriptCode) ;

  JsFunction setter = context[setterName] as JsFunction ;

  setter.apply([ (dynamic o) => f(o) ]) ;
  
}

void disableZooming() {

  String scriptCode = '''
  
  if ( window.UIConsole == null ) {
    UIConsole = function(o) {}  
  }
  
  var _blockZoom_lastTime = new Date() ;
  
  var blockZoom = function(event) {
    var s = event.scale ;
    
    if (s > 1 || s < 1) {
      var now = new Date() ;
      var elapsedTime = now.getTime() - _blockZoom_lastTime.getTime() ;
      
      if (elapsedTime > 1000) {
        UIConsole('Block event['+ event.type +'].scale:'+ s) ;
      }
      
      _blockZoom_lastTime = now ;
      event.preventDefault();
    }
  }
  
  block = function(types) {
    UIConsole('Block scale event of types: '+types) ;
    
    for (var i = 0; i < types.length; i++) {
      var t = types[i];
      window.addEventListener(t, blockZoom, { passive: false } );
    }
  }
  
  block( ["gesturestart", "gestureupdate", "gestureend", "touchenter", "touchstart", "touchmove", "touchend", "touchleave"]);
  
  ''';

  addJScript(scriptCode) ;

}

String getElementAttribute(Element element, dynamic key) {
  if (element == null || key == null) return null ;

  if (key is RegExp) {
    return getElementAttributeRegExp(element , key) ;
  }
  else {
    return getElementAttributeStr(element , key.toString()) ;
  }
}

String getElementAttributeRegExp(Element element, RegExp key) {
  if (element == null || key == null) return null ;

  var attrs = element.attributes;

  for (var k in attrs.keys) {
    if ( key.hasMatch(k) ) {
      return attrs[k] ;
    }
  }

  return null ;
}

String getElementAttributeStr(Element element, String key) {
  if (element == null || key == null) return null ;

  var val = element.getAttribute(key) ;
  if (val != null) return val;

  key = key.trim();
  key = key.toLowerCase();

  var attrs = element.attributes;

  for (var k in attrs.keys) {
    if (k.toLowerCase() == key) {
      return attrs[k] ;
    }
  }

  return null ;
}

dynamic callObjectMethod(dynamic o, String method, [List args]) {

  return callMethod(o, method, args);
}

String getHrefHost() {
  var href = window.location.href;
  var uri = Uri.parse(href);
  return uri.host;
}

RegExp _regExp_localhostHref = new RegExp('^(?:localhost|127\\.0\\.0\\.1)\$') ;

bool isLocalhostHref() {
  String host = getHrefHost();
  return _regExp_localhostHref.hasMatch( host ) ;
}

RegExp _regExp_IpHref = new RegExp('^\\d+\\.\\d+\\.\\d+\\.\\d+\$') ;

bool isIPtHref() {
  String host = getHrefHost();
  return _regExp_IpHref.hasMatch( host ) ;
}

void clearSelections() {
  var selection = window.getSelection() ;

  if (selection != null) {
    selection.removeAllRanges();
  }
}

String toHTML(Element e) {
  return _toHTML_any(e) ;
}

String _toHTML_any(Element e) {
  String html = "";

  html += "<" ;
  html += e.tagName ;

  for (var attr in e.attributes.keys) {
    var val = e.attributes[attr] ;
    if (val != null) {
      if (val.contains("'")) {
        html += " attr=\"$val\"" ;
      }
      else {
        html += " attr='$val'" ;
      }
    }
    else {
      html += " attr" ;
    }
  }

  html += ">" ;

  if ( e.innerHtml != null && e.innerHtml.isNotEmpty ) {

    if ( e is SelectElement ) {
      html += _toHTML_innerHtml_Select(e) ;
    }
    else {
      html += e.innerHtml ;
    }

  }

  html += "</${ e.tagName }>" ;

  return html ;
}

String _toHTML_innerHtml_Select(SelectElement e) {
  String html = "" ;

  for (var o in e.options) {
    html += "<option value='${o.value}' ${ o.selected ? ' selected' : ''}>${o.label}</option>";
  }

  return html ;
}

