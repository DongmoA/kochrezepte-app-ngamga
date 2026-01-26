# RecipeShare - Projektdokumentation

**Eine Cross-Platform Kochrezepte-Verwaltungs- und Austausch-App**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=flat-square&logo=supabase&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)

*Entwickelt im Rahmen von Cross-Platform Development WiSe25/26*

---

## Inhaltsverzeichnis

1. [Projektübersicht](#projektübersicht)
2. [Technische Umsetzung](#technische-umsetzung)
3. [Systemarchitektur](#systemarchitektur)
4. [Anforderungen & Umsetzung](#anforderungen--umsetzung)
5. [Fazit](#fazit)

---

## Projektübersicht

### Was ist RecipeShare?

RecipeShare ist eine moderne mobile Anwendung zur Verwaltung und zum Austausch von Kochrezepten zwischen Benutzern. Die App kombiniert persönliche Rezeptverwaltung mit Community-Features und bietet eine umfassende Lösung für alle, die ihre Lieblingsrezepte organisieren und mit anderen teilen möchten.

### Hauptfunktionen

**Rezeptverwaltung**
- Vollständige CRUD-Funktionalität (Erstellen, Lesen, Bearbeiten, Löschen)
- Upload und Verwaltung von Rezeptbildern
- Kategorisierung durch Tags (z.B. Vegan, Glutenfrei, Vegetarisch)
- Automatische Nährwertberechnung mit USDA FoodData Central API

**Social Features**
- 5-Sterne-Bewertungssystem mit Kommentaren
- Teilen von Rezepten via Email, WhatsApp, Telegram
- Merkzettel-Funktion für Favoriten
- Entdecken von neuen und beliebten Rezepten der Community

**Planungs-Tools**
- Wochenplan zur Mahlzeitenplanung
- Automatische Einkaufsliste aus Rezeptzutaten
- Manuelle Bearbeitung und Status-Tracking der Einkaufsliste

**Erweiterte Suchfunktionen**
- Suche nach Rezeptnamen, Zutaten und Tags
- Filterung nach Ernährungspräferenzen

**Benutzerverwaltung**
- Sichere Authentifizierung (Registrierung/Anmeldung)
- Profilverwaltung mit Ernährungspräferenzen
- Personalisierte Rezeptvorschläge

---

## Technische Umsetzung

### Technologie-Stack

**Frontend - Cross-Platform Mobile**
- Flutter/Dart für native iOS und Android Apps
- Material Design 3 für moderne UI
- StatefulWidget für State Management
- PopScope für Navigation mit Bestätigungsdialogen

**Backend - Cloud Infrastructure**
- Supabase als Backend-as-a-Service
- PostgreSQL-Datenbank
- Authentication System
- Storage Buckets für Bildverwaltung

**Externe APIs & Services**
- USDA FoodData Central API für Nährwertdaten
- LibreTranslate API für automatische DE↔EN Übersetzung
- MyMemory API als Fallback-Übersetzungsdienst
- Share Plus Plugin für plattformübergreifendes Teilen

### Projektstruktur

```
recipeshare/
├── lib/
│   ├── main.dart                    # App-Einstiegspunkt
│   ├── pages/                       # UI-Screens
│   │   ├── home_page.dart
│   │   ├── recipe_detail_page.dart
│   │   ├── recipe_form_page.dart
│   │   ├── weekly_plan_page.dart
│   │   ├── buy_list_page.dart
│   │   ├── profile_page.dart
│   │   ├── login_page.dart
│   │   └── register_page.dart
│   ├── services/                    # Business Logic
│   │   ├── database_service.dart
│   │   ├── auth_service.dart
│   │   └── nutrition_api_service.dart
│   ├── models/                      # Datenmodelle
│   │   ├── recipe.dart
│   │   ├── ingredient.dart
│   │   ├── instruction.dart
│   │   ├── rating.dart
│   │   └── profile.dart
│   └── widgets/                     # Wiederverwendbare Komponenten
├── assets/                          # Bilder, Fonts, etc.
├── test/                            # Tests
└── pubspec.yaml                     # Projekt-Konfiguration
```

### Installation und Setup

**Voraussetzungen**
1. Visual Studio Code installieren
2. Flutter SDK von https://flutter.dev/docs/get-started/install installieren

**Flutter-Version überprüfen**
```bash
flutter --version
```

**Projekt klonen und starten**
```bash
# Repository klonen
git clone git@git.thm.de:xd-praktikum/ws-25/kochrezepte-app-ngamga.git

# Dependencies installieren
flutter pub get

# App starten
flutter run
```

**Browser auswählen**
- 1 -> Windows (windows)
- 2 -> Chrome (chrome)
- 3 -> Edge (edge)

### Verwendete Packages

```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.0.7
  intl: ^0.18.0
  flutter_dotenv: ^5.1.0
  cupertino_icons: ^1.0.8
  supabase_flutter: ^2.10.3
  share_plus: ^12.0.1
```

### Projektstandards

**Code-Konventionen**
- camelCase für Variablen und Funktionen
- PascalCase für Klassen
- Feature-basierte Organisation
- Dokumentation komplexer Logik

**State Management**
- StatefulWidget für UI-State
- Dirty-Flag System für ungespeicherte Änderungen
- PopScope für Navigation mit Bestätigungsdialogen

**Error Handling**
- Try-Catch-Blöcke für API-Calls
- Retry-Logik bei Netzwerkfehlern
- Benutzerfreundliche Fehlermeldungen

**Performance-Optimierung**
- Parallele API-Verarbeitung mit `Future.wait()`
- Caching für Übersetzungen
- Lazy Loading für Listen

---

## Systemarchitektur

### Architektur-Übersicht

Die RecipeShare-App folgt einer mehrschichtigen Architektur mit klarer Trennung von Präsentations-, Geschäftslogik- und Datenschicht.

```
┌─────────────────────────────────────────────────────────┐
│         PRESENTATION LAYER (UI)                         │
├─────────────────────────────────────────────────────────┤
│  Home Page | Recipe Detail | Recipe Form               │
│  Weekly Plan | Buy List | Profile                       │
│  Login/Register Pages                                   │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│         BUSINESS LOGIC LAYER                            │
├─────────────────────────────────────────────────────────┤
│  DatabaseService | AuthService                          │
│  NutritionApiService | TranslationService               │
│  StorageService                                         │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│         DATA LAYER                                      │
├─────────────────────────────────────────────────────────┤
│  Supabase Backend:                                      │
│  • PostgreSQL-Datenbank                                 │
│  • Authentication System                                │
│  • Storage Buckets                                      │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│         EXTERNAL SERVICES                               │
├─────────────────────────────────────────────────────────┤
│  USDA FoodData Central API | LibreTranslate API         │
│  MyMemory API | Share Plus Plugin                       │
└─────────────────────────────────────────────────────────┘
```

### Datenbank-Schema

**profiles**
- Speichert Benutzerprofile und Ernährungspräferenzen
- Felder: id, username, diet_preference, created_at, updated_at
- Relation: 1:N zu recipes, ratings, bookmarks

**recipes**
- Haupttabelle für Rezeptdaten
- Felder: id, user_id, title, description, difficulty, prep_time, servings, tags, image_url, created_at
- Relation: N:1 zu profiles, 1:N zu ingredients, instructions, ratings

**ingredients**
- Zutaten eines Rezepts mit Nährwertdaten
- Felder: id, recipe_id, name, quantity, unit, calories, protein, carbs, fat
- Relation: N:1 zu recipes

**instructions**
- Schritt-für-Schritt Anweisungen
- Felder: id, recipe_id, step_number, description
- Relation: N:1 zu recipes

**ratings**
- Bewertungen und Kommentare
- Felder: id, recipe_id, user_id, rating, comment, created_at
- Relation: N:1 zu recipes und profiles

**bookmarks**
- Gespeicherte Favoriten-Rezepte
- Felder: id, recipe_id, user_id, created_at
- Relation: N:1 zu recipes und profiles

**weekly_plans**
- Wochenplanung für Mahlzeiten
- Felder: id, user_id, recipe_id, day_of_week, created_at
- Relation: N:1 zu recipes und profiles

**shopping_list**
- Einkaufslisten-Einträge
- Felder: id, user_id, name, quantity, unit, is_bought
- Relation: N:1 zu profiles

### Kommunikation zwischen Systemen

**Mobile App ↔ Supabase Backend**
- Protokoll: HTTPS REST API
- Datenaustausch: JSON-Format
- Real-time: Optional über Supabase Realtime

**App ↔ USDA FoodData Central API**
- Protokoll: HTTPS REST API
- Authentifizierung: API-Key
- Error Handling: Retry-Logik mit exponential backoff

**App ↔ Übersetzungs-APIs**
- Primär: LibreTranslate (Open-Source)
- Fallback: MyMemory API
- Cache-System: Lokales Caching häufiger Übersetzungen
- Performance: Parallele Verarbeitung mit `Future.wait()`

**App ↔ Share Plus**
- Integration: Native Platform-Integration
- Unterstützte Kanäle: Email, WhatsApp, Telegram, etc.
- Datenformat: Text oder strukturierte Daten

### Wichtige Workflows

**Rezept erstellen mit Nährwertberechnung**
1. Benutzer gibt Rezeptdaten ein (UI)
2. App sendet Zutatenliste an TranslationService
3. Parallele Übersetzung DE→EN für jede Zutat
4. NutritionApiService fragt USDA API ab
5. Aggregation der Nährwertdaten
6. DatabaseService speichert alles
7. StorageService lädt Bild hoch
8. UI wird aktualisiert

**Rezept bewerten**
1. Benutzer öffnet Rezept-Detailseite
2. Klick auf "Bewerten" Button
3. Bewertungs-Dialog erscheint (Sterne + optionaler Kommentar)
4. DatabaseService prüft, ob bereits bewertet wurde
5. UPDATE oder INSERT der Bewertung
6. Durchschnittsbewertung neu berechnen
7. UI aktualisiert Sterne-Anzeige

**Wochenplan erstellen**
1. Benutzer öffnet Wochenplan-Seite
2. Klick auf "Rezept hinzufügen" für Tag
3. Rezept auswählen aus eigenen/Community/Merkzettel
4. DatabaseService: INSERT in weekly_plans
5. UI aktualisiert Wochenplan
6. Optional: Zutaten zu Einkaufsliste hinzufügen

**Einkaufsliste generieren**
1. Benutzer öffnet Einkaufsliste
2. Klick auf "Aus Wochenplan importieren"
3. DatabaseService lädt alle Rezepte aus weekly_plans
4. Zutaten aggregieren (gleiche Zutaten zusammenfassen)
5. Duplikate prüfen
6. Neue Items in shopping_list einfügen
7. UI zeigt aktualisierte Liste mit Gruppierung

### Technische Herausforderungen & Lösungen

**API-Übersetzung**
- Problem: USDA API liefert nur englische Lebensmittel-Namen
- Lösung: Automatische DE↔EN Übersetzung mit LibreTranslate + MyMemory Fallback und lokalem Cache

**Nährwert-Performance**
- Problem: 25+ sequenzielle API-Calls verursachten Ladezeiten von 30+ Sekunden
- Lösung: Parallele Verarbeitung mit `Future.wait()` reduzierte Ladezeit auf 3-5 Sekunden

**State Management**
- Problem: Tracking ungespeicherter Änderungen bei Rezept-Bearbeitung
- Lösung: Dirty-Flag System mit `PopScope` für Bestätigungs-Dialoge

**UI/UX Optimierung**
- Problem: Layout-Probleme auf kleinen Geräten
- Lösung: Responsive Design mit `MediaQuery` und `LayoutBuilder`

---

## Anforderungen & Umsetzung

### Obligatorische Anforderungen

| Status | Anforderung | Beschreibung |
|--------|-------------|--------------|
| ✓ | CRUD von Rezepten | Erstellen, Lesen, Bearbeiten und Löschen von Rezepten mit Bildern, Zutaten, Anweisungen und Metadaten |
| ✓ | Verschlagwortung | Kategorisierung durch Tags wie Vegan, Glutenfrei, Vegetarisch |
| ✓ | Nährwertansicht | Automatische Berechnung mit USDA API, Anzeige pro Rezept und pro Portion |
| ✓ | Rezeptsuche | Suche nach Namen, Zutaten und Tags mit Filterung nach Ernährungspräferenzen |
| ✓ | Bewertungssystem | 5-Sterne-Bewertung mit optionalen Kommentaren |
| ✓ | Teilen-Funktion | Teilen via Email, WhatsApp, Telegram und andere Messenger |
| ✓ | Benutzer-Authentifizierung | Sichere Registrierung und Anmeldung mit Email/Passwort |

**Alle definierten Anforderungen wurden erfolgreich umgesetzt.**

### Mögliche zukünftige Erweiterungen

**Erweiterte Social Features**
- Follower-System für Benutzer
- Rezept-Collections (Sammlungen)
- Personalisierte User Feeds

**KI-Integration**
- Intelligente Rezept-Empfehlungen
- Automatische Zutatenerkennung per Foto
- Generierung von Rezepten aus vorhandenen Zutaten

**Offline-Modus**
- Lokale Datenspeicherung mit SQLite
- Automatische Synchronisation
- Offline-Zugriff auf gespeicherte Rezepte

**Erweiterte Analysen**
- Nährwert-Tracking über Zeit
- Ernährungsstatistiken und Visualisierungen
- Zielerreichungs-Dashboard

**Multi-Language Support**
- Vollständige Internationalisierung
- Automatische Übersetzung aller App-Inhalte
- Mehrsprachige Rezepte

**Smart Device Integration**
- Anbindung an Smart Kitchen Appliances
- Sprachsteuerung
- Smart Home Integration

---

## Fazit

### Projekterfolge

RecipeShare demonstriert die Entwicklung einer vollständigen Cross-Platform Mobile App mit modernem Tech-Stack:

- **Vollständige Anforderungserfüllung**: Alle obligatorischen und optionalen Anforderungen wurden implementiert
- **Professionelles Design**: Moderne UI/UX mit Material Design 3 und durchdachten Workflows
- **Robuste Backend-Integration**: Zuverlässige Anbindung an Supabase mit PostgreSQL
- **Innovative API-Integration**: Intelligente Kombination von USDA, Übersetzungs-APIs und Caching
- **Performance-Optimierung**: Parallele Verarbeitung reduzierte API-Ladezeiten um 85%
- **Skalierbare Architektur**: Klare Trennung von Präsentations-, Business- und Data-Layer

### Gewonnene Erkenntnisse

**Flutter State Management & Navigation**
- Effektive Nutzung von StatefulWidget für reaktive UI
- Implementation von Dirty-Flag Systemen für komplexe Workflows
- Moderne Navigation mit PopScope für bessere UX

**API-Integration & Error Handling**
- Robuste Fehlerbehandlung mit Retry-Logik
- Fallback-Strategien für externe Dienste
- Cache-Implementierung für Performance

**Datenbank-Design & Supabase**
- Normalisiertes Schema für relationale Daten
- Effiziente Queries mit PostgreSQL
- Integration von Authentication und Storage

**Performance-Optimierung**
- Parallele API-Verarbeitung mit `Future.wait()`
- Lazy Loading für große Datensätze
- Responsive Design für verschiedene Geräte

### Team

**Entwickelt von:**
- Ange Dongmo
- Hylarie Nzeye
- Manuela Djomkam
- Ken Ulrich Nya

**Zeitraum:** Wintersemester 2025/26

---

*RecipeShare - Kochrezepte verwalten, entdecken und teilen.*