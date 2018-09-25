
import 'dart:html';

import 'package:intl/intl.dart';
import 'package:intl/intl_browser.dart' ;

import 'package:swiss_knife/src/locales.dart';

class LocalesManagerBrowser extends LocalesManager {

  LocalesManagerBrowser(InitializeLocaleFunction initializeLocaleFunction, [ void onDefineLocale(String locale) ]) : super(initializeLocaleFunction, onDefineLocale) ;

  final String _LOCAL_KEY_locales_preferredLocale = "__locales__preferredLocale" ;

  @override
  String defineLocaleFromSystem() {
    findSystemLocale() ;
    return Intl.systemLocale ;
  }

  @override
  String readPreferredLocale() {
    return window.localStorage[_LOCAL_KEY_locales_preferredLocale] ;
  }

  @override
  storePreferredLocale(String locale) {
    window.localStorage[_LOCAL_KEY_locales_preferredLocale] = locale ;
  }

  @override
  List<String> getLocalesSequence(String locale) {
    return getPossibleLocalesSequenceInBrowser(locale) ;
  }

  SelectElement languageSelectElement( refreshOnChange() ) {
    var currentLocale = getCurrentLocale();
    var currentLocaleShort = Intl.shortLocale(currentLocale) ;

    SelectElement selectElement = new SelectElement() ;

    var initializedLocales = getInitializedLocales();

    bool currentLocaleInitialized = initializedLocales.contains(currentLocale) ;

    for (var l in initializedLocales ) {
      var localeName = getLocaleName(l, defaultName: l, nativeName: true, nativeLocale: '*', preserveLatinNames: true);
      var sel = (l == currentLocale) || (!currentLocaleInitialized && l == currentLocaleShort) ;

      var opt = new OptionElement(value: l, data: localeName, selected: sel);
      selectElement.children.add(opt) ;
    }

    var initializeAllLocales = this.initializeAllLocales() ;

    if (refreshOnChange != null) {
      initializeAllLocales.then((ok) {
        if (ok) refreshOnChange();
      });
    }

    selectElement.onChange.listen((e) {
      var locale = selectElement.selectedOptions[0].value ;
      print("selected language: $locale") ;
      setPreferredLocale(locale);
      if (refreshOnChange != null) refreshOnChange();
    });

    return selectElement ;
  }

}


List<String> getPossibleLocalesSequenceInBrowser(String locale) {
  var similarLocales = getSimilarLocales(locale);

  List<String> possibleLocalesSequence = [ Intl.canonicalizedLocale(locale) ] ;

  bool firstIsShortLocale = possibleLocalesSequence[0].length == 2 ;

  int similarPrioritySize = firstIsShortLocale ? 2 : 3 ;

  for (var l in similarLocales) {
    if ( !possibleLocalesSequence.contains(l) ) {
      possibleLocalesSequence.add(l) ;
      if (possibleLocalesSequence.length >= similarPrioritySize) break ;
    }
  }

  print("window.navigator.language: ${ window.navigator.language } ; ${ window.navigator.languages } ") ;

  for (var l in window.navigator.languages) {
    l = Intl.canonicalizedLocale(l) ;
    if ( !possibleLocalesSequence.contains(l) ) {
      possibleLocalesSequence.add(l) ;
    }
  }

  for (var l in similarLocales) {
    if ( !possibleLocalesSequence.contains(l) ) {
      possibleLocalesSequence.add(l) ;
    }
  }

  print("possibleLocalesSequence[browser]: $possibleLocalesSequence") ;

  return possibleLocalesSequence ;
}

