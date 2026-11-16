# Graph Report - lib  (2026-11-15)

## Corpus Check
- Corpus is ~16,393 words - fits in a single context window. You may not need a graph.

## Summary
- 730 nodes · 952 edges · 31 communities (28 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Escrow Orders Page
- Discovery Controller Repository
- Shared UI Widgets
- Barter Hub Page
- Discovery Data Layer
- Main Shell Navigation
- App Config Theme
- DI and Routing
- Color Tokens
- Geo Haversine Utils
- Discovery Filter Chips
- Spacing Radius Shadows
- Campus Map Widgets
- Service Listing Entity
- Home Section Widgets
- Private Page Components
- Campus Map Page
- Home Discovery Page
- Search Page
- Discovery Filter Entity
- Service Card Widgets
- Service Detail Page
- SVG Icon Widget
- App Entry Point
- Debouncer Utility
- Formatters
- Discovery State Scope
- Route Callsites
- Profile Placeholder
- Dashed Border Painter
- Orders Route Opener

## God Nodes (most connected - your core abstractions)
1. `DiscoveryController` - 7 edges
2. `ServiceListing` - 4 edges
3. `DiscoveryRepository` - 4 edges
4. `build` - 4 edges
5. `build` - 4 edges
6. `MainShell` - 3 edges
7. `_MainShellState` - 3 edges
8. `GeoPoint` - 3 edges
9. `BarterHubPage` - 3 edges
10. `_BarterHubPageState` - 3 edges

## Surprising Connections (you probably didn't know these)
- `DiscoveryRepositoryImpl` --implements--> `DiscoveryRepository`  [EXTRACTED]
  features/discovery/data/repositories/discovery_repository_impl.dart → features/discovery/domain/repositories/discovery_repository.dart
- `DiscoveryScope` --references--> `DiscoveryController`  [EXTRACTED]
  features/discovery/presentation/controllers/discovery_scope.dart → features/discovery/presentation/controllers/discovery_controller.dart

## Import Cycles
- None detected.

## Communities (31 total, 3 thin omitted)

### Community 0 - "Escrow Orders Page"
Cohesion: 0.03
Nodes (72): active, activeColor, _activeCount, amount, _blue, _blueSoft, buf, build (+64 more)

### Community 1 - "Discovery Controller Repository"
Cohesion: 0.05
Nodes (38): DiscoveryRepositoryImpl, DiscoveryRepository, DiscoveryResult, getCategories, isFallback, listings, searchNearby, call (+30 more)

### Community 2 - "Shared UI Widgets"
Cohesion: 0.05
Nodes (36): build, InitialsAvatar, name, ringColor, size, build, height, label (+28 more)

### Community 3 - "Barter Hub Page"
Cohesion: 0.04
Nodes (44): background, BarterContractView, _bg, build, code, color, completed, contract (+36 more)

### Community 4 - "Discovery Data Layer"
Cohesion: 0.05
Nodes (24): _around, categories, DiscoveryLocalDataSource, getCategories, getListings, _baseUrl, _client, DiscoveryException (+16 more)

### Community 5 - "Main Shell Navigation"
Cohesion: 0.05
Nodes (32): build, createState, current, didChangeDependencies, _discovery, dispose, goTo, icon (+24 more)

### Community 6 - "App Config Theme"
Cohesion: 0.05
Nodes (26): _apiOverride, AppConfig, campusCenter, campusLabel, defaultRadiusMeters, mapAttribution, mapTileSubdomains, mapTileUrl (+18 more)

### Community 7 - "DI and Routing"
Cohesion: 0.06
Nodes (20): AppScope, createDiscoveryController, dependencies, discoveryRepository, of, offline, production, updateShouldNotify (+12 more)

### Community 8 - "Color Tokens"
Cohesion: 0.06
Nodes (32): accent, AppColors, bannerBody, barter, barterBorder, barterSurface, barterText, borderLight (+24 more)

### Community 9 - "Geo Haversine Utils"
Cohesion: 0.08
Nodes (20): distanceKm, distanceMeters, earthRadiusMeters, formatDistance, GeoPoint, hashCode, Haversine, isWithinRadius (+12 more)

### Community 10 - "Discovery Filter Chips"
Cohesion: 0.08
Nodes (22): build, categories, CategoryChipsRow, categoryIcon, controller, FilterChipPill, FilterChipTone, HomeFilterChips (+14 more)

### Community 11 - "Spacing Radius Shadows"
Cohesion: 0.09
Nodes (20): AppRadius, AppShadows, AppSpacing, card, cardBr, emeraldGlow, flat, input (+12 more)

### Community 12 - "Campus Map Widgets"
Cohesion: 0.09
Nodes (17): build, build, CampusMapLabel, compactDistance, icon, listing, MapCircleButton, onOpenDetail (+9 more)

### Community 13 - "Service Listing Entity"
Cohesion: 0.09
Nodes (20): acceptsBarter, acceptsPayment, apiValue, category, copyWith, description, distanceMeters, fromApi (+12 more)

### Community 14 - "Home Section Widgets"
Cohesion: 0.09
Nodes (21): actionLabel, AiEstimatorButton, balance, BrandHeader, build, EscrowPromiseBanner, hint, LocationBalanceRow (+13 more)

### Community 15 - "Private Page Components"
Cohesion: 0.12
Nodes (16): _ApprovalRow, BarterPlaceholderPage, _ContractCard, _DealBox, _Pill, RadiusPills, _DetailChip, _DetailProof (+8 more)

### Community 16 - "Campus Map Page"
Cohesion: 0.12
Nodes (11): build, createState, dispose, _fitRadius, _fittedRadius, _focus, _map, _mapReady (+3 more)

### Community 17 - "Home Discovery Page"
Cohesion: 0.13
Nodes (7): controller, _demoBalance, _demoLocation, _demoUserName, _FeedSliver, HomeDiscoveryPage, _pad

### Community 18 - "Search Page"
Cohesion: 0.13
Nodes (10): _clear, _controller, createState, _debouncer, didChangeDependencies, dispose, initialFilter, _onQueryChanged (+2 more)

### Community 19 - "Discovery Filter Entity"
Cohesion: 0.14
Nodes (11): barterOnly, categoryId, copyWith, DiscoveryFilter, hashCode, hasQuery, minRating, operator (+3 more)

### Community 20 - "Service Card Widgets"
Cohesion: 0.14
Nodes (11): BarterBadge, build, color, DistanceLabel, fontSize, listing, meters, onTap (+3 more)

### Community 21 - "Service Detail Page"
Cohesion: 0.14
Nodes (8): _BarterInfoBox, _DetailActionBar, _iconKey, listing, _PriceRow, ServiceDetailPage, ServiceMediaBanner, _soon

### Community 22 - "SVG Icon Widget"
Cohesion: 0.14
Nodes (9): asset, bookmark, build, color, icon, SakuIcon, SakuIcons, semanticLabel (+1 more)

### Community 23 - "App Entry Point"
Cohesion: 0.18
Nodes (5): build, dependencies, SakuSkillApp, AppDependencies, main

### Community 24 - "Debouncer Utility"
Cohesion: 0.20
Nodes (5): Debouncer, delay, dispose, run, _timer

### Community 25 - "Formatters"
Cohesion: 0.20
Nodes (9): buffer, digits, formatRupiah, initialsOf, join, letters, negative, parts (+1 more)

### Community 26 - "Discovery State Scope"
Cohesion: 0.22
Nodes (4): DiscoveryController, DiscoveryScope, of, read

### Community 27 - "Route Callsites"
Cohesion: 0.33
Nodes (3): _bottomContent, build, build

## Knowledge Gaps
- **465 isolated node(s):** `dependencies`, `build`, `AppConfig`, `_apiOverride`, `useMockData` (+460 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 544 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `DiscoveryController` connect `Discovery State Scope` to `Discovery Controller Repository`, `Main Shell Navigation`, `Discovery Filter Chips`, `Home Discovery Page`, `Search Page`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **What connects `dependencies`, `build`, `AppConfig` to the rest of the system?**
  _465 weakly-connected nodes found - possible missing edges._
- **Should `Escrow Orders Page` be split into smaller, more focused modules?**
  _Cohesion score 0.02666666666666667 - nodes in this community are weakly interconnected._
- **Why does `Debouncer` connect `Debouncer Utility` to `Search Page`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Should `Discovery Controller Repository` be split into smaller, more focused modules?**
  _Cohesion score 0.04521276595744681 - nodes in this community are weakly interconnected._
- **Why does `DiscoveryRepository` connect `Discovery Controller Repository` to `DI and Routing`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **Should `Shared UI Widgets` be split into smaller, more focused modules?**
  _Cohesion score 0.04810360777058279 - nodes in this community are weakly interconnected._