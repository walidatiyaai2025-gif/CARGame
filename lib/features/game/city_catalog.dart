import 'level_data.dart';

const worldCities = <List<String>>[
  [
    'Brookfield', 'Riverside', 'Oakridge', 'Fairview', 'Hillcrest',
    'Lakeside', 'Greenwood', 'Maple Town', 'Sunnyvale', 'Westport',
    'Eastgate', 'Pinehurst', 'Cedar Bay', 'Silver Creek', 'Grand Junction',
    'Stonebridge', 'Meadow Park', 'Clearwater', 'Northfield', 'Southpoint',
    'Golden Valley', 'Redwood', 'Bluewater', 'Kingsport', 'Capital Depot',
  ],
  [
    'Metro Center', 'Neon Avenue', 'Commerce City', 'Tech District', 'Market Square',
    'Central Station', 'Skyline', 'Downtown', 'Uptown', 'Innovation Park',
    'Financial Quarter', 'Grand Boulevard', 'City Gardens', 'Urban Heights', 'Victory Plaza',
    'Liberty Point', 'Crown District', 'Crystal City', 'New Horizon', 'Unity Square',
    'Commerce Gate', 'Royal Avenue', 'Emerald City', 'Imperial Center', 'Mega City',
  ],
  [
    'Coral Port', 'Marina Bay', 'Anchor Point', 'Blue Harbor', 'Oceanview',
    'Pearl Coast', 'Seaside', 'Docklands', 'Wave City', 'Cape Harbor',
    'Tidewater', 'Port Victoria', 'Sailor Bay', 'Atlantic Gate', 'Pacific Wharf',
    'Coral Island', 'Deepwater', 'Sea Breeze', 'Lighthouse City', 'Harbor Heights',
    'Trade Winds', 'Ocean Terminal', 'Captain’s Port', 'Royal Marina', 'Grand Harbor',
  ],
  [
    'Oasis Town', 'Sandstone', 'Desert Rose', 'Golden Dunes', 'Palm City',
    'Mirage', 'Sunset Oasis', 'Caravan Gate', 'Amber Valley', 'Sahara Point',
    'Canyon City', 'Nomad Camp', 'Copper Ridge', 'Desert Springs', 'Falcon City',
    'Dune Harbor', 'Solar Town', 'Red Mesa', 'Spice Market', 'Silk Route',
    'Royal Oasis', 'Phoenix City', 'Sun Kingdom', 'Diamond Dunes', 'Desert Capital',
  ],
  [
    'Cloud City', 'Aero Bay', 'Runway One', 'Skyline Hub', 'Jetstream',
    'Nimbus Town', 'Altitude', 'Blue Sky', 'Cloud Nine', 'Airbridge',
    'Pilot City', 'Horizon Gate', 'Aviation Park', 'Starport', 'Wing Valley',
    'Sky Gardens', 'Flight Deck', 'Air Cargo City', 'Stratosphere', 'Moonlight Bay',
    'Aurora Point', 'Eagle City', 'Celestial Hub', 'Sky Kingdom', 'Global Airport',
  ],
  [
    'Nova City', 'Quantum Bay', 'Orbit Station', 'Fusion Point', 'Titan District',
    'Galaxy Gate', 'Cyber City', 'Infinity Hub', 'Mars Colony', 'Lunar Base',
    'Stellar Port', 'Photon City', 'Cosmic Center', 'Future Town', 'Vertex',
    'Hyperion', 'Andromeda', 'Solaris', 'Eclipse City', 'Nebula Prime',
    'Omega Station', 'Genesis', 'Universe Gate', 'World Nexus', 'Global Command',
  ],
];

extension CityLevelData on LevelData {
  int get cityIndex => (number - 1) % 25;
  String get cityName => worldCities[world - 1][cityIndex];
  bool get isBossCity => cityIndex == 24;
}
