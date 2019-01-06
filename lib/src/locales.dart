
import 'dart:async';

import 'package:swiss_knife/src/utils.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';

List<String> _LATIN_LANGUAGES = [
  "en",
  "es",
  "fr",
  "de",
  "it",
  "pt",

  "is",
  "ga",
  "ro",
  "sv",
];

Map<String,String> _NATIVE_LOCALES_NAMES = {
  "en": "English",
  "en_US": "English (United States)",
  "en_GB": "English (United Kingdom)",
  "en_CA": "English (Canada)",
  "en_AU": "English (Australia)",
  "en_NZ": "English (New Zealand)",
  "en_ZA": "English (South Africa)",

  "es": "Español",
  "es_ES": "Español (España)",
  "es_MX": "Español (Méjico)",

  "fr": "Français",
  "fr_FR": "Français (France)",
  "fr_CA": "Français (Canada)",
  "fr_BE": "Français (Belgique)",
  "fr_CH": "Français (Suisse)",
  "fr_MC": "Français (Monaco)",
  "fr_LU": "Français (Luxembourg)",

  "de": "Deutsche",
  "de_DE": "Deutsche (Deutschland)",
  "de_AT": "Deutsche (Österreich)",
  "de_CH": "Deutsche (Schweiz)",
  "de_BE": "Deutsche (Belgien)",
  "de_LU": "Deutsche (Luxemburg)",
  "de_LI": "Deutsche (Liechtenstein)",

  "it": "Italiano",
  "it_IT": "Italiano (Italia)",
  "it_CH": "Italiano (Svizzera)",

  "pt": "Português",
  "pt_BR": "Português (Brasil)",
  "pt_PT": "Português (Portugal)",

  "ja": "日本語",
  "ja_JP": "日本語 (日本)",

  "zh": "中文",
  "zh_Hans": "中文 (简体汉)",

  "ru": "русский",
  "ru_RU": "русский (Россия)",

  "ko": "한국어",
  "ko_KR": "한국어 (대한민국)",
};

Map<String,String> _ALL_LOCALES = {

  "en": "English",
  "en_US": "English (United States)",
  "en_GB": "English (United Kingdom)",
  "en_CA": "English (Canada)",
  "en_AU": "English (Australia)",
  "en_NZ": "English (New Zealand)",
  "en_ZA": "English (South Africa)",

  "zh": "Chinese",
  "zh_Hans": "Chinese (Simplified Han)",
  "zh_Hans_CN": "Chinese (Simplified Han, China)",
  "zh_Hans_HK": "Chinese (Simplified Han, Hong Kong SAR China)",
  "zh_Hans_SG": "Chinese (Simplified Han, Singapore)",
  "zh_Hans_MO": "Chinese (Simplified Han, Macau SAR China)",

  "es": "Spanish",
  "es_ES": "Spanish (Spain)",
  "es_MX": "Spanish (Mexico)",
  "es_419": "Spanish (Latin America)",
  "es_US": "Spanish (United States)",

  "fr": "French",
  "fr_FR": "French (France)",
  "fr_CA": "French (Canada)",
  "fr_BE": "French (Belgium)",
  "fr_CH": "French (Switzerland)",
  "fr_MC": "French (Monaco)",
  "fr_LU": "French (Luxembourg)",

  "de": "German",
  "de_DE": "German (Germany)",
  "de_AT": "German (Austria)",
  "de_CH": "German (Switzerland)",
  "de_BE": "German (Belgium)",
  "de_LU": "German (Luxembourg)",
  "de_LI": "German (Liechtenstein)",

  "it": "Italian",
  "it_IT": "Italian (Italy)",
  "it_CH": "Italian (Switzerland)",

  "pt": "Portuguese",
  "pt_BR": "Portuguese (Brazil)",
  "pt_PT": "Portuguese (Portugal)",

  "ja": "Japanese",
  "ja_JP": "Japanese (Japan)",

  "ar": "Arabic",
  "ar_EG": "Arabic (Egypt)",
  "ar_SA": "Arabic (Saudi Arabia)",
  "ar_KW": "Arabic (Kuwait)",
  "ar_MA": "Arabic (Morocco)",
  "ar_QA": "Arabic (Qatar)",
  "ar_DZ": "Arabic (Algeria)",
  "ar_BH": "Arabic (Bahrain)",
  "ar_IQ": "Arabic (Iraq)",
  "ar_JO": "Arabic (Jordan)",
  "ar_LB": "Arabic (Lebanon)",
  "ar_LY": "Arabic (Libya)",
  "ar_OM": "Arabic (Oman)",
  "ar_SD": "Arabic (Sudan)",
  "ar_SY": "Arabic (Syria)",
  "ar_TN": "Arabic (Tunisia)",
  "ar_AE": "Arabic (United Arab Emirates)",
  "ar_YE": "Arabic (Yemen)",

  "ru": "Russian",
  "ru_RU": "Russian (Russia)",

  "ko": "Korean",
  "ko_KR": "Korean (South Korea)",

  //////////////////////////////////


  "en_VI": "English (U.S. Virgin Islands)",
  "en_IE": "English (Ireland)",
  "en_BE": "English (Belgium)",
  "en_IN": "English (India)",
  "en_HK": "English (Hong Kong SAR China)",
  "en_JM": "English (Jamaica)",
  "en_AS": "English (American Samoa)",
  "en_BZ": "English (Belize)",
  "en_BW": "English (Botswana)",
  "en_GU": "English (Guam)",
  "en_MT": "English (Malta)",
  "en_MH": "English (Marshall Islands)",
  "en_MU": "English (Mauritius)",
  "en_NA": "English (Namibia)",
  "en_MP": "English (Northern Mariana Islands)",
  "en_PK": "English (Pakistan)",
  "en_PH": "English (Philippines)",
  "en_SG": "English (Singapore)",
  "en_TT": "English (Trinidad and Tobago)",
  "en_UM": "English (U.S. Minor Outlying Islands)",
  "en_ZW": "English (Zimbabwe)",

  "zh_Hant": "Chinese (Traditional Han)",
  "zh_Hant_HK": "Chinese (Traditional Han, Hong Kong SAR China)",
  "zh_Hant_TW": "Chinese (Traditional Han, Taiwan)",
  "zh_Hant_MO": "Chinese (Traditional Han, Macau SAR China)",

  "es_CL": "Spanish (Chile)",
  "es_CO": "Spanish (Colombia)",
  "es_AR": "Spanish (Argentina)",
  "es_BO": "Spanish (Bolivia)",
  "es_CR": "Spanish (Costa Rica)",
  "es_DO": "Spanish (Dominican Republic)",
  "es_EC": "Spanish (Ecuador)",
  "es_SV": "Spanish (El Salvador)",
  "es_GQ": "Spanish (Equatorial Guinea)",
  "es_GT": "Spanish (Guatemala)",
  "es_HN": "Spanish (Honduras)",
  "es_NI": "Spanish (Nicaragua)",
  "es_PA": "Spanish (Panama)",
  "es_PY": "Spanish (Paraguay)",
  "es_PE": "Spanish (Peru)",
  "es_PR": "Spanish (Puerto Rico)",
  "es_UY": "Spanish (Uruguay)",
  "es_VE": "Spanish (Venezuela)",


  "fr_BJ": "French (Benin)",
  "fr_BF": "French (Burkina Faso)",
  "fr_BI": "French (Burundi)",
  "fr_CM": "French (Cameroon)",
  "fr_CF": "French (Central African Republic)",
  "fr_TD": "French (Chad)",
  "fr_KM": "French (Comoros)",
  "fr_CG": "French (Congo - Brazzaville)",
  "fr_CD": "French (Congo - Kinshasa)",
  "fr_CI": "French (Côte d’Ivoire)",
  "fr_DJ": "French (Djibouti)",
  "fr_GQ": "French (Equatorial Guinea)",
  "fr_GA": "French (Gabon)",
  "fr_GP": "French (Guadeloupe)",
  "fr_GN": "French (Guinea)",
  "fr_MG": "French (Madagascar)",
  "fr_ML": "French (Mali)",
  "fr_MQ": "French (Martinique)",
  "fr_NE": "French (Niger)",
  "fr_RW": "French (Rwanda)",
  "fr_RE": "French (Réunion)",
  "fr_BL": "French (Saint Barthélemy)",
  "fr_MF": "French (Saint Martin)",
  "fr_SN": "French (Senegal)",
  "fr_TG": "French (Togo)",

  "pt_MZ": "Portuguese (Mozambique)",
  "pt_GW": "Portuguese (Guinea-Bissau)",

  "ru_UA": "Russian (Ukraine)",
  "ru_MD": "Russian (Moldova)",

  //////////////////////////////////

  "af_NA": "Afrikaans (Namibia)",
  "af_ZA": "Afrikaans (South Africa)",
  "af": "Afrikaans",
  "ak_GH": "Akan (Ghana)",
  "ak": "Akan",
  "sq_AL": "Albanian (Albania)",
  "sq": "Albanian",
  "am_ET": "Amharic (Ethiopia)",
  "am": "Amharic",

  "hy_AM": "Armenian (Armenia)",
  "hy": "Armenian",
  "as_IN": "Assamese (India)",
  "as": "Assamese",
  "asa_TZ": "Asu (Tanzania)",
  "asa": "Asu",
  "az_Cyrl": "Azerbaijani (Cyrillic)",
  "az_Cyrl_AZ": "Azerbaijani (Cyrillic, Azerbaijan)",
  "az_Latn": "Azerbaijani (Latin)",
  "az_Latn_AZ": "Azerbaijani (Latin, Azerbaijan)",
  "az": "Azerbaijani",
  "bm_ML": "Bambara (Mali)",
  "bm": "Bambara",
  "eu_ES": "Basque (Spain)",
  "eu": "Basque",
  "be_BY": "Belarusian (Belarus)",
  "be": "Belarusian",
  "bem_ZM": "Bemba (Zambia)",
  "bem": "Bemba",
  "bez_TZ": "Bena (Tanzania)",
  "bez": "Bena",
  "bn_BD": "Bengali (Bangladesh)",
  "bn_IN": "Bengali (India)",
  "bn": "Bengali",
  "bs_BA": "Bosnian (Bosnia and Herzegovina)",
  "bs": "Bosnian",
  "bg_BG": "Bulgarian (Bulgaria)",
  "bg": "Bulgarian",
  "my_MM": "Burmese (Myanmar [Burma])",
  "my": "Burmese",
  "ca_ES": "Catalan (Spain)",
  "ca": "Catalan",
  "tzm_Latn": "Central Morocco Tamazight (Latin)",
  "tzm_Latn_MA": "Central Morocco Tamazight (Latin, Morocco)",
  "tzm": "Central Morocco Tamazight",
  "chr_US": "Cherokee (United States)",
  "chr": "Cherokee",
  "cgg_UG": "Chiga (Uganda)",
  "cgg": "Chiga",

  "kw_GB": "Cornish (United Kingdom)",
  "kw": "Cornish",
  "hr_HR": "Croatian (Croatia)",
  "hr": "Croatian",
  "cs_CZ": "Czech (Czech Republic)",
  "cs": "Czech",
  "da_DK": "Danish (Denmark)",
  "da": "Danish",
  "nl_BE": "Dutch (Belgium)",
  "nl_NL": "Dutch (Netherlands)",
  "nl": "Dutch",
  "ebu_KE": "Embu (Kenya)",
  "ebu": "Embu",


  "eo": "Esperanto",
  "et_EE": "Estonian (Estonia)",
  "et": "Estonian",
  "ee_GH": "Ewe (Ghana)",
  "ee_TG": "Ewe (Togo)",
  "ee": "Ewe",
  "fo_FO": "Faroese (Faroe Islands)",
  "fo": "Faroese",
  "fil_PH": "Filipino (Philippines)",
  "fil": "Filipino",
  "fi_FI": "Finnish (Finland)",
  "fi": "Finnish",

  "ff_SN": "Fulah (Senegal)",
  "ff": "Fulah",
  "gl_ES": "Galician (Spain)",
  "gl": "Galician",
  "lg_UG": "Ganda (Uganda)",
  "lg": "Ganda",
  "ka_GE": "Georgian (Georgia)",
  "ka": "Georgian",

  "el_CY": "Greek (Cyprus)",
  "el_GR": "Greek (Greece)",
  "el": "Greek",
  "gu_IN": "Gujarati (India)",
  "gu": "Gujarati",
  "guz_KE": "Gusii (Kenya)",
  "guz": "Gusii",
  "ha_Latn": "Hausa (Latin)",
  "ha_Latn_GH": "Hausa (Latin, Ghana)",
  "ha_Latn_NE": "Hausa (Latin, Niger)",
  "ha_Latn_NG": "Hausa (Latin, Nigeria)",
  "ha": "Hausa",
  "haw_US": "Hawaiian (United States)",
  "haw": "Hawaiian",
  "he_IL": "Hebrew (Israel)",
  "he": "Hebrew",
  "hi_IN": "Hindi (India)",
  "hi": "Hindi",
  "hu_HU": "Hungarian (Hungary)",
  "hu": "Hungarian",
  "is_IS": "Icelandic (Iceland)",
  "is": "Icelandic",
  "ig_NG": "Igbo (Nigeria)",
  "ig": "Igbo",
  "id_ID": "Indonesian (Indonesia)",
  "id": "Indonesian",
  "ga_IE": "Irish (Ireland)",
  "ga": "Irish",

  "kea_CV": "Kabuverdianu (Cape Verde)",
  "kea": "Kabuverdianu",
  "kab_DZ": "Kabyle (Algeria)",
  "kab": "Kabyle",
  "kl_GL": "Kalaallisut (Greenland)",
  "kl": "Kalaallisut",
  "kln_KE": "Kalenjin (Kenya)",
  "kln": "Kalenjin",
  "kam_KE": "Kamba (Kenya)",
  "kam": "Kamba",
  "kn_IN": "Kannada (India)",
  "kn": "Kannada",
  "kk_Cyrl": "Kazakh (Cyrillic)",
  "kk_Cyrl_KZ": "Kazakh (Cyrillic, Kazakhstan)",
  "kk": "Kazakh",
  "km_KH": "Khmer (Cambodia)",
  "km": "Khmer",
  "ki_KE": "Kikuyu (Kenya)",
  "ki": "Kikuyu",
  "rw_RW": "Kinyarwanda (Rwanda)",
  "rw": "Kinyarwanda",
  "kok_IN": "Konkani (India)",
  "kok": "Konkani",

  "khq_ML": "Koyra Chiini (Mali)",
  "khq": "Koyra Chiini",
  "ses_ML": "Koyraboro Senni (Mali)",
  "ses": "Koyraboro Senni",
  "lag_TZ": "Langi (Tanzania)",
  "lag": "Langi",
  "lv_LV": "Latvian (Latvia)",
  "lv": "Latvian",
  "lt_LT": "Lithuanian (Lithuania)",
  "lt": "Lithuanian",
  "luo_KE": "Luo (Kenya)",
  "luo": "Luo",
  "luy_KE": "Luyia (Kenya)",
  "luy": "Luyia",
  "mk_MK": "Macedonian (Macedonia)",
  "mk": "Macedonian",
  "jmc_TZ": "Machame (Tanzania)",
  "jmc": "Machame",
  "kde_TZ": "Makonde (Tanzania)",
  "kde": "Makonde",
  "mg_MG": "Malagasy (Madagascar)",
  "mg": "Malagasy",
  "ms_BN": "Malay (Brunei)",
  "ms_MY": "Malay (Malaysia)",
  "ms": "Malay",
  "ml_IN": "Malayalam (India)",
  "ml": "Malayalam",
  "mt_MT": "Maltese (Malta)",
  "mt": "Maltese",
  "gv_GB": "Manx (United Kingdom)",
  "gv": "Manx",
  "mr_IN": "Marathi (India)",
  "mr": "Marathi",
  "mas_KE": "Masai (Kenya)",
  "mas_TZ": "Masai (Tanzania)",
  "mas": "Masai",
  "mer_KE": "Meru (Kenya)",
  "mer": "Meru",
  "mfe_MU": "Morisyen (Mauritius)",
  "mfe": "Morisyen",
  "naq_NA": "Nama (Namibia)",
  "naq": "Nama",
  "ne_IN": "Nepali (India)",
  "ne_NP": "Nepali (Nepal)",
  "ne": "Nepali",
  "nd_ZW": "North Ndebele (Zimbabwe)",
  "nd": "North Ndebele",
  "nb_NO": "Norwegian Bokmål (Norway)",
  "nb": "Norwegian Bokmål",
  "nn_NO": "Norwegian Nynorsk (Norway)",
  "nn": "Norwegian Nynorsk",
  "nyn_UG": "Nyankole (Uganda)",
  "nyn": "Nyankole",
  "or_IN": "Oriya (India)",
  "or": "Oriya",
  "om_ET": "Oromo (Ethiopia)",
  "om_KE": "Oromo (Kenya)",
  "om": "Oromo",
  "ps_AF": "Pashto (Afghanistan)",
  "ps": "Pashto",
  "fa_AF": "Persian (Afghanistan)",
  "fa_IR": "Persian (Iran)",
  "fa": "Persian",
  "pl_PL": "Polish (Poland)",
  "pl": "Polish",

  "pa_Arab": "Punjabi (Arabic)",
  "pa_Arab_PK": "Punjabi (Arabic, Pakistan)",
  "pa_Guru": "Punjabi (Gurmukhi)",
  "pa_Guru_IN": "Punjabi (Gurmukhi, India)",
  "pa": "Punjabi",
  "ro_MD": "Romanian (Moldova)",
  "ro_RO": "Romanian (Romania)",
  "ro": "Romanian",
  "rm_CH": "Romansh (Switzerland)",
  "rm": "Romansh",
  "rof_TZ": "Rombo (Tanzania)",
  "rof": "Rombo",

  "rwk_TZ": "Rwa (Tanzania)",
  "rwk": "Rwa",
  "saq_KE": "Samburu (Kenya)",
  "saq": "Samburu",
  "sg_CF": "Sango (Central African Republic)",
  "sg": "Sango",
  "seh_MZ": "Sena (Mozambique)",
  "seh": "Sena",
  "sr_Cyrl": "Serbian (Cyrillic)",
  "sr_Cyrl_BA": "Serbian (Cyrillic, Bosnia and Herzegovina)",
  "sr_Cyrl_ME": "Serbian (Cyrillic, Montenegro)",
  "sr_Cyrl_RS": "Serbian (Cyrillic, Serbia)",
  "sr_Latn": "Serbian (Latin)",
  "sr_Latn_BA": "Serbian (Latin, Bosnia and Herzegovina)",
  "sr_Latn_ME": "Serbian (Latin, Montenegro)",
  "sr_Latn_RS": "Serbian (Latin, Serbia)",
  "sr": "Serbian",
  "sn_ZW": "Shona (Zimbabwe)",
  "sn": "Shona",
  "ii_CN": "Sichuan Yi (China)",
  "ii": "Sichuan Yi",
  "si_LK": "Sinhala (Sri Lanka)",
  "si": "Sinhala",
  "sk_SK": "Slovak (Slovakia)",
  "sk": "Slovak",
  "sl_SI": "Slovenian (Slovenia)",
  "sl": "Slovenian",
  "xog_UG": "Soga (Uganda)",
  "xog": "Soga",
  "so_DJ": "Somali (Djibouti)",
  "so_ET": "Somali (Ethiopia)",
  "so_KE": "Somali (Kenya)",
  "so_SO": "Somali (Somalia)",
  "so": "Somali",

  "sw_KE": "Swahili (Kenya)",
  "sw_TZ": "Swahili (Tanzania)",
  "sw": "Swahili",
  "sv_FI": "Swedish (Finland)",
  "sv_SE": "Swedish (Sweden)",
  "sv": "Swedish",
  "gsw_CH": "Swiss German (Switzerland)",
  "gsw": "Swiss German",
  "shi_Latn": "Tachelhit (Latin)",
  "shi_Latn_MA": "Tachelhit (Latin, Morocco)",
  "shi_Tfng": "Tachelhit (Tifinagh)",
  "shi_Tfng_MA": "Tachelhit (Tifinagh, Morocco)",
  "shi": "Tachelhit",
  "dav_KE": "Taita (Kenya)",
  "dav": "Taita",
  "ta_IN": "Tamil (India)",
  "ta_LK": "Tamil (Sri Lanka)",
  "ta": "Tamil",
  "te_IN": "Telugu (India)",
  "te": "Telugu",
  "teo_KE": "Teso (Kenya)",
  "teo_UG": "Teso (Uganda)",
  "teo": "Teso",
  "th_TH": "Thai (Thailand)",
  "th": "Thai",
  "bo_CN": "Tibetan (China)",
  "bo_IN": "Tibetan (India)",
  "bo": "Tibetan",
  "ti_ER": "Tigrinya (Eritrea)",
  "ti_ET": "Tigrinya (Ethiopia)",
  "ti": "Tigrinya",
  "to_TO": "Tonga (Tonga)",
  "to": "Tonga",
  "tr_TR": "Turkish (Turkey)",
  "tr": "Turkish",
  "uk_UA": "Ukrainian (Ukraine)",
  "uk": "Ukrainian",
  "ur_IN": "Urdu (India)",
  "ur_PK": "Urdu (Pakistan)",
  "ur": "Urdu",
  "uz_Arab": "Uzbek (Arabic)",
  "uz_Arab_AF": "Uzbek (Arabic, Afghanistan)",
  "uz_Cyrl": "Uzbek (Cyrillic)",
  "uz_Cyrl_UZ": "Uzbek (Cyrillic, Uzbekistan)",
  "uz_Latn": "Uzbek (Latin)",
  "uz_Latn_UZ": "Uzbek (Latin, Uzbekistan)",
  "uz": "Uzbek",
  "vi_VN": "Vietnamese (Vietnam)",
  "vi": "Vietnamese",
  "vun_TZ": "Vunjo (Tanzania)",
  "vun": "Vunjo",
  "cy_GB": "Welsh (United Kingdom)",
  "cy": "Welsh",
  "yo_NG": "Yoruba (Nigeria)",
  "yo": "Yoruba",
  "zu_ZA": "Zulu (South Africa)",
  "zu": "Zulu"
} ;

List<String> LATIN_LANGUAGES() {
  return new List.from(_LATIN_LANGUAGES) ;
}

Map<String,String> ALL_LOCALES() {
  return new Map.from(_ALL_LOCALES) ;
}

List<String> ALL_LOCALES_CODES() {
  return new List.from(_ALL_LOCALES.keys) ;
}

String getLocaleName(String locale, {String defaultName, bool nativeName = false, String nativeLocale, bool preserveLatinNames = true}) {
  locale = Intl.canonicalizedLocale(locale) ;
  String localeShort = Intl.shortLocale(locale);

  String name =_ALL_LOCALES[locale] ;

  if (name == null) {
    name =_ALL_LOCALES[localeShort] ;
  }

  if (nativeName && name != null) {
    String nameGlobal = name ;

    if (nativeLocale == "*") {
      if ( _NATIVE_LOCALES_NAMES.containsKey(locale) ) name = _NATIVE_LOCALES_NAMES[locale] ;
    }
    else {
      if (nativeLocale == null || nativeLocale == '.') nativeLocale = getCurrentLocale();
      String nativeLocaleShort = Intl.shortLocale(nativeLocale);

      if ( nativeLocale == locale || localeShort == nativeLocaleShort ) {
        name = _NATIVE_LOCALES_NAMES[locale] ;
      }
    }

    if (name != nameGlobal && !_LATIN_LANGUAGES.contains(localeShort)) {
      String nameShort =_ALL_LOCALES[localeShort] ;

      name = "$name -- $nameShort" ;
    }
  }

  return name != null ? name : defaultName;
}

List<String> getSimilarLocales(String locale) {
  var canonicalizedLocale = Intl.canonicalizedLocale(locale);

  var shortLocale = Intl.shortLocale(canonicalizedLocale) ;

  List<String> list = _ALL_LOCALES.keys.where((l) => l == shortLocale || l.startsWith("${shortLocale}_")).toList(growable: true) ;

  return list ;
}

////////////////////////////////////////////////////////////////////////////////

typedef Future<bool> LocaleInitializeFunction(String locale) ;

class LocaleInitializer {

  final LocaleInitializeFunction initializeFunction ;
  final List<String> _locales ;

  Completer<bool> _completer ;

  LocaleInitializer(this.initializeFunction, this._locales) {

    this._completer = new Completer() ;

    _initializeIdx(0) ;
  }

  Future<bool> get future => _completer.future ;

  void _initializeIdx(int idx) {
    if (idx >= _locales.length) {
      _completer.complete(false) ;
      return ;
    }

    String locale = _locales[idx] ;

    print("Trying to initialize locale[${idx+1}/${_locales.length}]: $locale") ;

    var future = initializeFunction(locale) ;

    if (future == null) {
      future = new Future.value(false) ;
    }

    future.then((ok) {
      _onInitialize(idx, ok) ;
    });
  }

  EventStream<String> onInitializeLocale = new EventStream() ;
  EventStream<String> onFailLocale = new EventStream() ;

  List<String> _failedLocales = [] ;
  List<String> get failedLocales => new List.from(_failedLocales) ;

  String _initializedLocale ;
  String get initializedLocale => _initializedLocale ;

  void _onInitialize(int idx, bool ok) {
    String locale = _locales[idx] ;

    print("_onInitialize: $locale > $ok") ;

    if (ok) {
      print("Locale initialized: $locale") ;

      _initializedLocale = locale ;
      onInitializeLocale.add(locale);

      _completer.complete(true) ;
    }
    else {
      _failedLocales.add(locale) ;
      onFailLocale.add(locale);
      _initializeIdx(idx+1) ;
    }
  }

}

////////////////////////////////////////////////////////////////////////////////

typedef Future<bool> InitializeLocaleFunction(String locale) ;

class LocalesManager {

  final InitializeLocaleFunction initializeLocaleFunction ;

  final Map<String,String> _localesAlternatives = {} ;
  final Map<String,bool> _initializedLocales = {} ;

  LocalesManager(this.initializeLocaleFunction, [ void onDefineLocale(String locale) ]) {
    if (onDefineLocale != null) {
      this.onDefineLocale.listen(onDefineLocale) ;
    }
  }

  bool isInitializedLocale(String locale) {
    return _initializedLocales.containsKey(locale) && _initializedLocales[locale] ;
  }

  bool isInitializedLocaleWithAlternative(String locale) {
    return getLocaleInitializedAlternative(locale) != null ;
  }

  bool isFailedLocale(String locale) {
    return _initializedLocales.containsKey(locale) && !_initializedLocales[locale] ;
  }

  String getLocaleInitializedAlternative(String locale) {
    return _localesAlternatives[locale] ;
  }

  List<String> getInitializedLocales() {
    return _initializedLocales.entries.where((e) => e.value).map((e) => e.key).toList() ;
  }

  List<String> getNotInitializedLocales( [bool includeFails = false] ) {
    List<String> locales = ALL_LOCALES_CODES();

    if (includeFails) {
      locales.removeWhere( (l) => _initializedLocales.containsKey(l) ) ;
    }
    else {
      locales.removeWhere( (l) => isInitializedLocale(l) || isInitializedLocaleWithAlternative(l) ) ;
    }

    return locales ;
  }

  Map<String, String> getInitializedLocalesAlternatives() {
    return new Map.from(_localesAlternatives) ;
  }

  String getCurrentLocale() {
    return Intl.defaultLocale ;
  }

  Future<bool> setPreferredLocale(String locale) {
    if (locale == null) {
      print("setPreferredLocale: null locale!") ;
      return new Future.value(false) ;
    }

    print("setPreferredLocale: $locale") ;

    storePreferredLocale(locale) ;

    return _defineLocale(locale);
  }

  String readPreferredLocale() {
    return null ;
  }

  storePreferredLocale(String locale) {

  }

  String defineLocaleFromSystem() {

  }

  Future<bool> _initialized ;

  Future<bool> initialize( String preferredLocale() ) {
    if (_initialized != null) return _initialized ;

    String locale = preferredLocale != null ? preferredLocale() : null ;

    if (locale == null) {
      locale = readPreferredLocale() ;
    }

    if (locale == null) {
      print("defineLocaleFromSystem()") ;
      locale = defineLocaleFromSystem() ;
      print("System locale: $locale") ;
    }

    _initialized = _defineLocale(locale) ;

    return _initialized ;
  }

  Future<bool> _defineLocale([String locale]) {
    print("Define locale: $locale") ;

    if ( isInitializedLocale(locale) ) {
      print("Locale already initialized: $locale") ;
      _defineInitializedLocale(locale) ;
      return new Future.value(true);
    }
    else if ( isFailedLocale(locale) ) {
      var alternative = getLocaleInitializedAlternative(locale) ;

      if (alternative != null) {
        print("Locale already initialized with alternative: $locale -> $alternative") ;
        _defineInitializedLocale(alternative) ;
        return new Future.value(true);
      }
      else {
        print("Locale already initialized and failed: $locale") ;
        return new Future.value(false);
      }
    }

    List<String> possibleLocalesSequence = getLocalesSequence(locale) ;

    var localeInitializer = new LocaleInitializer( (s) => _callInitializeLocale(s, true) , possibleLocalesSequence) ;

    if (localeInitializer == null) {
      return new Future.value(false) ;
    }

    localeInitializer.onFailLocale.listen((l) {
      _initializedLocales[l] = false ;
    });

    var futureInitializeLocale = localeInitializer.future;

    return futureInitializeLocale.then((ok) {
      if (ok) {
        var locale = localeInitializer.initializedLocale ;
        var localeShort = Intl.shortLocale(locale);

        for (var l in localeInitializer.failedLocales) {
          if ( Intl.shortLocale(l) == localeShort ) {
            _localesAlternatives[l] = locale;
          }
        }

        _onLocaleInitialized(locale) ;
      }

      return ok ;
    });
  }

  void _onLocaleInitialized(String locale) {
    _initializedLocales[locale] = true ;

    print("Initialized locales: ${ getInitializedLocales() } ; alternatives: ${ getInitializedLocalesAlternatives()}") ;

    _defineInitializedLocale(locale) ;
  }

  EventStream<String> onDefineLocale = new EventStream() ;

  void _defineInitializedLocale(String locale) {
    Intl.defaultLocale = locale ;

    print("Locale defined: $locale") ;

    try {
      initializeDateFormatting(locale, null);
    }
    catch (e) {
      print(e) ;
    }

    onDefineLocale.add(locale) ;
  }

  List<String> getLocalesSequence(String locale) {
    return getPossibleLocalesSequence( locale ) ;
  }

  Future<bool> initializeAllLocales() {
    var notInitializedLocales = getNotInitializedLocales(true) ;
    if (notInitializedLocales.isEmpty) return new Future.value(false) ;

    Map<String, int> initializations = {} ;

    Completer<bool> completer = new Completer();

    List<String> initOrder = getLocalesSequence( getCurrentLocale() ) ;

    for (var l in new List.from(initOrder)) {
      var similarLocales = getSimilarLocales(l);
      similarLocales.removeWhere((s) => initOrder.contains(s)) ;
      initOrder.addAll(similarLocales) ;
    }

    initOrder.addAll(notInitializedLocales) ;

    for (var l in initOrder) {
      l = Intl.canonicalizedLocale(l) ;

      if ( initializations.containsKey(l) || isInitializedLocale(l) || isInitializedLocaleWithAlternative(l) ) {
        continue ;
      }

      var futureInit = _callInitializeLocale(l, true) ;
      if (futureInit == null) continue ;

      initializations[l] = 0 ;

      futureInit.then((ok) {
        _initializedLocales[l] = ok ;

        initializations[l] = ok ? 1 : 2 ;

        bool completed = initializations.values
            .where((v) => v == 0)
            .toList()
            .isEmpty;

        if (completed) {
          bool anyInit = initializations.values
              .where((v) => v == 1)
              .toList()
              .isNotEmpty;

          _onInitializeAllLocales() ;

          completer.complete(anyInit) ;
        }
      });
    }

    if (initializations.isEmpty) {
      completer.complete(false) ;
    }

    return completer.future ;
  }

  void _onInitializeAllLocales() {

    for (var l in _initializedLocales.keys) {
      bool lOk = _initializedLocales[l] ;

      if (!lOk) {
        var similarLocales = getSimilarLocales(l);

        List<String> alternatives = similarLocales.where((l) => _initializedLocales[l]).toList();

        if ( alternatives.isNotEmpty ) {
          _localesAlternatives[l] = alternatives[0] ;
        }
      }
    }

  }

  Future<bool> _callInitializeLocale(String locale, bool strictLocale) {
    if (locale == null) throw new StateError("Null Locale!") ;

    var future = initializeLocaleFunction(locale) ;
    if (future == null) return null ;

    return future.then((ok) {
      if (!ok) {
        return false ;
      }
      else if (strictLocale) {
        bool loadedLocale = isLoadedLocale(locale) ;
        bool loaded = loadedLocale != null ? loadedLocale : true ;
        return loaded ;
      }
      else {
        return true ;
      }
    }) ;
  }

}



////////////////////////////////////////////////////////////////////////////////

bool isLoadedLocale(String locale) {
  var lookup = messageLookup;
  
  if ( lookup is CompositeMessageLookup ) {
    return lookup.availableMessages.containsKey(locale) ;
  }

  return null ;
}

List<String> getLoadedLocales() {
  var lookup = messageLookup;

  if ( lookup is CompositeMessageLookup ) {
    return lookup.availableMessages.keys ;
  }

  return null ;
}

List<String> getPossibleLocalesSequence(String locale) {
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

  for (var l in similarLocales) {
    if ( !possibleLocalesSequence.contains(l) ) {
      possibleLocalesSequence.add(l) ;
    }
  }

  print("possibleLocalesSequence: $possibleLocalesSequence") ;

  return possibleLocalesSequence ;
}


/////////////////////////////////////////////////////////////////////////////////////////


String getCurrentLocale() {
  var locale = Intl.defaultLocale;
  return locale != null ? locale : "en" ;
}

String get messageLanguage => messageLanguageByLocale( getCurrentLocale() ) ;
String get messageIdiom => messageIdiomByLocale( getCurrentLocale() ) ;

String messageLanguageByLocale(String locale) {
  locale = locale != null ? Intl.shortLocale(locale) : '' ;

  if (locale == 'en') return "Language" ;
  if (locale == 'pt') return "Língua" ;

  if (locale == 'es') return "Idioma" ;
  if (locale == 'it') return "Linguaggio" ;
  if (locale == 'fr') return "Langage" ;
  if (locale == 'de') return "Sprache" ;

  if (locale == 'ru') return "язык" ;
  if (locale == 'ja') return "言語" ;
  if (locale == 'ko') return "언어" ;
  if (locale == 'zh') return "语言" ;

  return "Idiom" ;
}

String messageIdiomByLocale(String locale) {
  locale = locale != null ? Intl.shortLocale(locale) : '' ;

  if (locale == 'en') return "Idiom" ;
  if (locale == 'pt') return "Idioma" ;

  if (locale == 'es') return "Idioma" ;
  if (locale == 'it') return "Idioma" ;
  if (locale == 'fr') return "Idiome" ;
  if (locale == 'de') return "Idiom" ;

  if (locale == 'ru') return "идиома" ;
  if (locale == 'ja') return "イディオム" ;
  if (locale == 'ko') return "관용구" ;
  if (locale == 'zh') return "成语" ;

  return "Idiom" ;
}
