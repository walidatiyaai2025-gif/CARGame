import 'level_data.dart';

class CapitalStage {
  const CapitalStage({
    required this.level,
    required this.countryCode,
    required this.countryEn,
    required this.countryAr,
    required this.capitalEn,
    required this.capitalAr,
    required this.latitude,
    required this.longitude,
  });

  final int level;
  final String countryCode;
  final String countryEn;
  final String countryAr;
  final String capitalEn;
  final String capitalAr;
  final double latitude;
  final double longitude;

  int get world => ((level - 1) ~/ 25) + 1;
  String country(bool isArabic) => isArabic ? countryAr : countryEn;
  String capital(bool isArabic) => isArabic ? capitalAr : capitalEn;
  String label(bool isArabic) =>
      isArabic ? '$capitalAr - $countryAr' : '$capitalEn, $countryEn';
}

class CapitalRoute {
  const CapitalRoute({
    required this.world,
    required this.nameEn,
    required this.nameAr,
    required this.subtitleEn,
    required this.subtitleAr,
  });

  final int world;
  final String nameEn;
  final String nameAr;
  final String subtitleEn;
  final String subtitleAr;

  String name(bool isArabic) => isArabic ? nameAr : nameEn;
  String subtitle(bool isArabic) => isArabic ? subtitleAr : subtitleEn;
}

const capitalRoutes = <CapitalRoute>[
  CapitalRoute(
    world: 1,
    nameEn: 'Western Europe',
    nameAr: 'أوروبا الغربية',
    subtitleEn: 'Europe begins with the Atlantic capitals',
    subtitleAr: 'ابدأ الرحلة من عواصم أوروبا المطلة على الأطلسي',
  ),
  CapitalRoute(
    world: 2,
    nameEn: 'Eastern Europe & Central Asia',
    nameAr: 'أوروبا الشرقية وآسيا الوسطى',
    subtitleEn: 'Cross Europe into the Caucasus and Central Asia',
    subtitleAr: 'اعبر شرق أوروبا والقوقاز وآسيا الوسطى',
  ),
  CapitalRoute(
    world: 3,
    nameEn: 'Asia',
    nameAr: 'آسيا',
    subtitleEn: 'Travel through East, South and Southeast Asia',
    subtitleAr: 'تنقّل بين شرق وجنوب وجنوب شرق آسيا',
  ),
  CapitalRoute(
    world: 4,
    nameEn: 'Middle East & East Africa',
    nameAr: 'الشرق الأوسط وشرق أفريقيا',
    subtitleEn: 'Connect the Gulf, North Africa and East Africa',
    subtitleAr: 'اربط الخليج وشمال أفريقيا وشرق أفريقيا',
  ),
  CapitalRoute(
    world: 5,
    nameEn: 'Africa',
    nameAr: 'أفريقيا',
    subtitleEn: 'Continue through central, western and southern Africa',
    subtitleAr: 'واصل الرحلة عبر وسط وغرب وجنوب أفريقيا',
  ),
  CapitalRoute(
    world: 6,
    nameEn: 'Americas & Oceania',
    nameAr: 'الأمريكتان وأوقيانوسيا',
    subtitleEn: 'Finish across the Americas, Australia and New Zealand',
    subtitleAr: 'اختتم الرحلة عبر الأمريكتين وأستراليا ونيوزيلندا',
  ),
];

const _capitalRows = <String>[
  'PT|Portugal|البرتغال|Lisbon|لشبونة|38.72|-9.14',
  'ES|Spain|إسبانيا|Madrid|مدريد|40.42|-3.70',
  'FR|France|فرنسا|Paris|باريس|48.86|2.35',
  'BE|Belgium|بلجيكا|Brussels|بروكسل|50.85|4.35',
  'NL|Netherlands|هولندا|Amsterdam|أمستردام|52.37|4.90',
  'LU|Luxembourg|لوكسمبورغ|Luxembourg|لوكسمبورغ|49.61|6.13',
  'GB|United Kingdom|المملكة المتحدة|London|لندن|51.51|-0.13',
  'IE|Ireland|أيرلندا|Dublin|دبلن|53.35|-6.26',
  'IS|Iceland|آيسلندا|Reykjavik|ريكيافيك|64.15|-21.94',
  'NO|Norway|النرويج|Oslo|أوسلو|59.91|10.75',
  'SE|Sweden|السويد|Stockholm|ستوكهولم|59.33|18.07',
  'FI|Finland|فنلندا|Helsinki|هلسنكي|60.17|24.94',
  'DK|Denmark|الدنمارك|Copenhagen|كوبنهاغن|55.68|12.57',
  'DE|Germany|ألمانيا|Berlin|برلين|52.52|13.41',
  'CH|Switzerland|سويسرا|Bern|برن|46.95|7.45',
  'AT|Austria|النمسا|Vienna|فيينا|48.21|16.37',
  'IT|Italy|إيطاليا|Rome|روما|41.90|12.50',
  'CZ|Czechia|التشيك|Prague|براغ|50.08|14.44',
  'SK|Slovakia|سلوفاكيا|Bratislava|براتيسلافا|48.15|17.11',
  'PL|Poland|بولندا|Warsaw|وارسو|52.23|21.01',
  'HU|Hungary|المجر|Budapest|بودابست|47.50|19.04',
  'SI|Slovenia|سلوفينيا|Ljubljana|ليوبليانا|46.06|14.51',
  'HR|Croatia|كرواتيا|Zagreb|زغرب|45.81|15.98',
  'BA|Bosnia and Herzegovina|البوسنة والهرسك|Sarajevo|سراييفو|43.86|18.41',
  'GR|Greece|اليونان|Athens|أثينا|37.98|23.73',
  'EE|Estonia|إستونيا|Tallinn|تالين|59.44|24.75',
  'LV|Latvia|لاتفيا|Riga|ريغا|56.95|24.11',
  'LT|Lithuania|ليتوانيا|Vilnius|فيلنيوس|54.69|25.28',
  'RO|Romania|رومانيا|Bucharest|بوخارست|44.43|26.10',
  'BG|Bulgaria|بلغاريا|Sofia|صوفيا|42.70|23.32',
  'RS|Serbia|صربيا|Belgrade|بلغراد|44.82|20.46',
  'ME|Montenegro|الجبل الأسود|Podgorica|بودغوريتسا|42.44|19.26',
  'MK|North Macedonia|مقدونيا الشمالية|Skopje|سكوبيه|42.00|21.43',
  'AL|Albania|ألبانيا|Tirana|تيرانا|41.33|19.82',
  'MD|Moldova|مولدوفا|Chisinau|كيشيناو|47.01|28.86',
  'UA|Ukraine|أوكرانيا|Kyiv|كييف|50.45|30.52',
  'BY|Belarus|بيلاروس|Minsk|مينسك|53.90|27.57',
  'RU|Russia|روسيا|Moscow|موسكو|55.76|37.62',
  'GE|Georgia|جورجيا|Tbilisi|تبليسي|41.72|44.79',
  'AM|Armenia|أرمينيا|Yerevan|يريفان|40.18|44.51',
  'AZ|Azerbaijan|أذربيجان|Baku|باكو|40.41|49.87',
  'TR|Turkey|تركيا|Ankara|أنقرة|39.93|32.86',
  'KZ|Kazakhstan|كازاخستان|Astana|أستانا|51.17|71.43',
  'UZ|Uzbekistan|أوزبكستان|Tashkent|طشقند|41.31|69.28',
  'KG|Kyrgyzstan|قيرغيزستان|Bishkek|بشكيك|42.87|74.60',
  'TJ|Tajikistan|طاجيكستان|Dushanbe|دوشنبه|38.56|68.78',
  'TM|Turkmenistan|تركمانستان|Ashgabat|عشق آباد|37.96|58.33',
  'CY|Cyprus|قبرص|Nicosia|نيقوسيا|35.17|33.36',
  'MT|Malta|مالطا|Valletta|فاليتا|35.90|14.51',
  'SM|San Marino|سان مارينو|San Marino|سان مارينو|43.94|12.45',
  'CN|China|الصين|Beijing|بكين|39.90|116.41',
  'MN|Mongolia|منغوليا|Ulaanbaatar|أولان باتور|47.92|106.92',
  'JP|Japan|اليابان|Tokyo|طوكيو|35.68|139.69',
  'KR|South Korea|كوريا الجنوبية|Seoul|سيول|37.57|126.98',
  'KP|North Korea|كوريا الشمالية|Pyongyang|بيونغ يانغ|39.04|125.76',
  'IN|India|الهند|New Delhi|نيودلهي|28.61|77.21',
  'PK|Pakistan|باكستان|Islamabad|إسلام آباد|33.69|73.06',
  'BD|Bangladesh|بنغلاديش|Dhaka|دكا|23.81|90.41',
  'NP|Nepal|نيبال|Kathmandu|كاتماندو|27.72|85.32',
  'BT|Bhutan|بوتان|Thimphu|تيمفو|27.47|89.64',
  'LK|Sri Lanka|سريلانكا|Sri Jayawardenepura Kotte|سري جاياواردنابورا كوتي|6.89|79.90',
  'MV|Maldives|المالديف|Male|ماليه|4.18|73.51',
  'AF|Afghanistan|أفغانستان|Kabul|كابول|34.56|69.21',
  'MM|Myanmar|ميانمار|Naypyidaw|نايبيداو|19.75|96.13',
  'TH|Thailand|تايلاند|Bangkok|بانكوك|13.76|100.50',
  'LA|Laos|لاوس|Vientiane|فيينتيان|17.97|102.60',
  'KH|Cambodia|كمبوديا|Phnom Penh|بنوم بنه|11.56|104.93',
  'VN|Vietnam|فيتنام|Hanoi|هانوي|21.03|105.85',
  'MY|Malaysia|ماليزيا|Kuala Lumpur|كوالالمبور|3.14|101.69',
  'SG|Singapore|سنغافورة|Singapore|سنغافورة|1.35|103.82',
  'ID|Indonesia|إندونيسيا|Jakarta|جاكرتا|-6.21|106.85',
  'PH|Philippines|الفلبين|Manila|مانيلا|14.60|120.98',
  'BN|Brunei|بروناي|Bandar Seri Begawan|بندر سري بكاوان|4.90|114.94',
  'TL|Timor-Leste|تيمور الشرقية|Dili|ديلي|-8.56|125.58',
  'IR|Iran|إيران|Tehran|طهران|35.69|51.39',
  'KW|Kuwait|الكويت|Kuwait City|مدينة الكويت|29.38|47.99',
  'SA|Saudi Arabia|السعودية|Riyadh|الرياض|24.71|46.67',
  'BH|Bahrain|البحرين|Manama|المنامة|26.23|50.59',
  'QA|Qatar|قطر|Doha|الدوحة|25.29|51.53',
  'AE|United Arab Emirates|الإمارات العربية المتحدة|Abu Dhabi|أبوظبي|24.45|54.38',
  'OM|Oman|عُمان|Muscat|مسقط|23.59|58.41',
  'YE|Yemen|اليمن|Sanaa|صنعاء|15.35|44.21',
  'JO|Jordan|الأردن|Amman|عمّان|31.95|35.91',
  'LB|Lebanon|لبنان|Beirut|بيروت|33.89|35.50',
  'SY|Syria|سوريا|Damascus|دمشق|33.51|36.29',
  'IQ|Iraq|العراق|Baghdad|بغداد|33.31|44.37',
  'EG|Egypt|مصر|Cairo|القاهرة|30.04|31.24',
  'LY|Libya|ليبيا|Tripoli|طرابلس|32.89|13.19',
  'TN|Tunisia|تونس|Tunis|تونس|36.81|10.18',
  'DZ|Algeria|الجزائر|Algiers|الجزائر|36.75|3.06',
  'MA|Morocco|المغرب|Rabat|الرباط|34.02|-6.84',
  'MR|Mauritania|موريتانيا|Nouakchott|نواكشوط|18.08|-15.98',
  'ET|Ethiopia|إثيوبيا|Addis Ababa|أديس أبابا|9.03|38.74',
  'ER|Eritrea|إريتريا|Asmara|أسمرة|15.32|38.93',
  'DJ|Djibouti|جيبوتي|Djibouti|جيبوتي|11.59|43.15',
  'SO|Somalia|الصومال|Mogadishu|مقديشو|2.05|45.32',
  'KE|Kenya|كينيا|Nairobi|نيروبي|-1.29|36.82',
  'UG|Uganda|أوغندا|Kampala|كمبالا|0.35|32.58',
  'RW|Rwanda|رواندا|Kigali|كيغالي|-1.94|30.06',
  'TZ|Tanzania|تنزانيا|Dodoma|دودوما|-6.16|35.75',
  'ZA|South Africa|جنوب أفريقيا|Pretoria|بريتوريا|-25.75|28.19',
  'NA|Namibia|ناميبيا|Windhoek|ويندهوك|-22.56|17.08',
  'BW|Botswana|بوتسوانا|Gaborone|غابورون|-24.63|25.91',
  'ZW|Zimbabwe|زيمبابوي|Harare|هراري|-17.83|31.05',
  'ZM|Zambia|زامبيا|Lusaka|لوساكا|-15.39|28.32',
  'MW|Malawi|مالاوي|Lilongwe|ليلونغوي|-13.96|33.79',
  'MZ|Mozambique|موزمبيق|Maputo|مابوتو|-25.97|32.58',
  'AO|Angola|أنغولا|Luanda|لواندا|-8.84|13.23',
  'CD|DR Congo|الكونغو الديمقراطية|Kinshasa|كينشاسا|-4.32|15.31',
  'CG|Republic of the Congo|جمهورية الكونغو|Brazzaville|برازافيل|-4.27|15.28',
  'GA|Gabon|الغابون|Libreville|ليبرفيل|0.39|9.45',
  'CM|Cameroon|الكاميرون|Yaounde|ياوندي|3.87|11.52',
  'NG|Nigeria|نيجيريا|Abuja|أبوجا|9.08|7.40',
  'GH|Ghana|غانا|Accra|أكرا|5.56|-0.20',
  'CI|Cote d\'Ivoire|ساحل العاج|Yamoussoukro|ياموسوكرو|6.82|-5.28',
  'SN|Senegal|السنغال|Dakar|داكار|14.72|-17.47',
  'GM|Gambia|غامبيا|Banjul|بانجول|13.45|-16.58',
  'GN|Guinea|غينيا|Conakry|كوناكري|9.64|-13.58',
  'SL|Sierra Leone|سيراليون|Freetown|فريتاون|8.47|-13.23',
  'LR|Liberia|ليبيريا|Monrovia|مونروفيا|6.30|-10.80',
  'ML|Mali|مالي|Bamako|باماكو|12.64|-8.00',
  'BF|Burkina Faso|بوركينا فاسو|Ouagadougou|واغادوغو|12.37|-1.52',
  'NE|Niger|النيجر|Niamey|نيامي|13.51|2.11',
  'BJ|Benin|بنين|Porto-Novo|بورتو نوفو|6.50|2.60',
  'TG|Togo|توغو|Lome|لومي|6.13|1.22',
  'CA|Canada|كندا|Ottawa|أوتاوا|45.42|-75.70',
  'US|United States|الولايات المتحدة|Washington, D.C.|واشنطن|38.91|-77.04',
  'MX|Mexico|المكسيك|Mexico City|مكسيكو سيتي|19.43|-99.13',
  'GT|Guatemala|غواتيمالا|Guatemala City|غواتيمالا سيتي|14.63|-90.52',
  'BZ|Belize|بليز|Belmopan|بلموبان|17.25|-88.77',
  'HN|Honduras|هندوراس|Tegucigalpa|تيغوسيغالبا|14.07|-87.19',
  'SV|El Salvador|السلفادور|San Salvador|سان سلفادور|13.69|-89.19',
  'NI|Nicaragua|نيكاراغوا|Managua|ماناغوا|12.11|-86.24',
  'CR|Costa Rica|كوستاريكا|San Jose|سان خوسيه|9.93|-84.08',
  'PA|Panama|بنما|Panama City|بنما سيتي|8.98|-79.52',
  'CU|Cuba|كوبا|Havana|هافانا|23.11|-82.37',
  'DO|Dominican Republic|جمهورية الدومينيكان|Santo Domingo|سانتو دومينغو|18.49|-69.93',
  'JM|Jamaica|جامايكا|Kingston|كينغستون|17.97|-76.79',
  'CO|Colombia|كولومبيا|Bogota|بوغوتا|4.71|-74.07',
  'VE|Venezuela|فنزويلا|Caracas|كاراكاس|10.48|-66.90',
  'EC|Ecuador|الإكوادور|Quito|كيتو|-0.18|-78.47',
  'PE|Peru|بيرو|Lima|ليما|-12.05|-77.04',
  'BO|Bolivia|بوليفيا|Sucre|سوكري|-19.04|-65.26',
  'CL|Chile|تشيلي|Santiago|سانتياغو|-33.45|-70.67',
  'AR|Argentina|الأرجنتين|Buenos Aires|بوينس آيرس|-34.60|-58.38',
  'BR|Brazil|البرازيل|Brasilia|برازيليا|-15.79|-47.88',
  'UY|Uruguay|أوروغواي|Montevideo|مونتيفيديو|-34.90|-56.16',
  'PY|Paraguay|باراغواي|Asuncion|أسونسيون|-25.26|-57.58',
  'AU|Australia|أستراليا|Canberra|كانبيرا|-35.28|149.13',
  'NZ|New Zealand|نيوزيلندا|Wellington|ويلينغتون|-41.29|174.78',
];

final List<CapitalStage> capitalStages = List<CapitalStage>.unmodifiable(
  List<CapitalStage>.generate(_capitalRows.length, (index) {
    final parts = _capitalRows[index].split('|');
    return CapitalStage(
      level: index + 1,
      countryCode: parts[0],
      countryEn: parts[1],
      countryAr: parts[2],
      capitalEn: parts[3],
      capitalAr: parts[4],
      latitude: double.parse(parts[5]),
      longitude: double.parse(parts[6]),
    );
  }),
);

CapitalStage capitalStageForLevel(int levelNumber) {
  if (levelNumber < 1 || levelNumber > capitalStages.length) {
    throw RangeError.range(levelNumber, 1, capitalStages.length, 'levelNumber');
  }
  return capitalStages[levelNumber - 1];
}

CapitalRoute capitalRouteForWorld(int world) {
  if (world < 1 || world > capitalRoutes.length) {
    throw RangeError.range(world, 1, capitalRoutes.length, 'world');
  }
  return capitalRoutes[world - 1];
}

final List<List<String>> worldCities = List<List<String>>.unmodifiable(
  List<List<String>>.generate(
    6,
    (worldIndex) => List<String>.unmodifiable(
      capitalStages
          .where((stage) => stage.world == worldIndex + 1)
          .map((stage) => stage.capitalEn),
    ),
  ),
);

extension CityLevelData on LevelData {
  int get cityIndex => (number - 1) % 25;
  CapitalStage get capitalStage => capitalStageForLevel(number);
  String get cityName => capitalStage.capitalEn;
  String get countryName => capitalStage.countryEn;
  String localizedCityName(bool isArabic) => capitalStage.capital(isArabic);
  String localizedCountryName(bool isArabic) => capitalStage.country(isArabic);
  String localizedDestinationLabel(bool isArabic) =>
      capitalStage.label(isArabic);
  bool get isBossCity => cityIndex == 24;
}
