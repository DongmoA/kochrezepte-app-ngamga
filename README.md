# RecipeShare - Projektdokumentation

## 1. Einleitung

**RecipeShare** ist eine Flutter-basierte Mobile- und Web-Anwendung zur Verwaltung von Koch- und Backrezepten. Die App ermöglicht es Benutzern, eigene Rezepte zu erstellen, zu bearbeiten und mit der Community zu teilen. 

### Hauptfunktionen

- **Rezeptverwaltung**: Erstellen, Bearbeiten und Löschen eigener Rezepte mit Bildern, Zutaten, Schritt-für-Schritt-Anleitungen und Nährwertangaben
- **Automatische Nährwertberechnung**: Integration der USDA FoodData Central API mit automatischer Deutsch-Englisch-Übersetzung
- **Wochenplanung**: Planung von Mahlzeiten für die gesamte Woche mit Drag-and-Drop-Funktionalität
- **Einkaufsliste**: Automatisches Generieren von Einkaufslisten aus Wochenplänen oder einzelnen Rezepten
- **Social Features**: Bewertungssystem, Favoriten, Rezepte teilen
- **Filterfunktionen**: Suche und Filter nach Tags, Zubereitungszeit, Mahlzeitentyp und mehr
- **Benutzerprofil**: Verwaltung von Ernährungspräferenzen und persönlichen Einstellungen

---

## 2. Technische Umsetzung

### 2.1 Verwendete Technologien

#### Frontend
- **Flutter**: 3.24.0 (Dart SDK: >=3.0.0 <4.0.0)
- **Hauptbibliotheken**:
  - `supabase_flutter: ^2.8.1` - Backend-Integration
  - `image_picker: ^1.1.2` - Bildauswahl
  - `share_plus: ^10.1.2` - Teilen-Funktionalität
  - `intl: ^0.19.0` - Internationalisierung und Datumsformatierung
  - `http: ^1.2.2` - HTTP-Anfragen für externe APIs

#### Backend
- **Supabase** (PostgreSQL-Datenbank + Authentication + Storage)
  - PostgreSQL Views für optimierte Abfragen
  - Row Level Security (RLS) für Datensicherheit
  - Storage Buckets für Rezeptbilder

#### Externe APIs
- **USDA FoodData Central API** - Nährwertdaten
- **LibreTranslate API** - Automatische Übersetzung DE↔EN
- **MyMemory Translation API** - Fallback-Übersetzung

### 2.2 Entwicklungsumgebung einrichten

#### Voraussetzungen
```bash
# Flutter SDK installieren (Version 3.24.0 oder höher)
flutter --version

# Android Studio oder VS Code mit Flutter/Dart Extensions
```

#### Projekt-Setup

**Schritt 1: Repository klonen**
```bash
git clone <repository-url>
cd kochrezepte_app
```

**Schritt 2: Dependencies installieren**
```bash
flutter pub get
```

### 2.3 Projektstruktur

```
lib/
├── main.dart                          # App-Einstiegspunkt
├── models/
│   └── recipe.dart                    # Datenmodelle (Recipe, Ingredient, etc.)
├── pages/
│   ├── home.dart                      # Hauptseite mit Rezeptliste
│   ├── profile_page.dart              # Benutzerprofil
│   ├── Login_signUp/
│   │   ├── login_page.dart           # Login-Formular
│   │   └── register_page.dart        # Registrierung
│   ├── Recipe/
│   │   ├── recipe_detail_page.dart   # Rezeptdetails & Bewertungen
│   │   └── recipe_form_page.dart     # Rezept erstellen/bearbeiten
│   └── Feature_extends/
│       ├── weeklyplan_page.dart      # Wochenplanung
│       └── buy_list_page.dart        # Einkaufsliste
├── widgets/
│   ├── recipe_card.dart              # Rezept-Kachel
│   ├── searchbar.dart                # Suchleiste
│   ├── filter_bottom_sheet.dart      # Filter-Dialog
│   ├── recipe_detail_items.dart      # UI-Komponenten für Details
│   └── rating_widget.dart            # Bewertungs-Widget
└── supabase/
    ├── supabase_client.dart          # Supabase-Initialisierung
    ├── auth_service.dart             # Authentifizierung
    ├── database_service.dart         # Datenbank-Operationen
    └── nutrition_api_service.dart    # USDA API Integration
```

### 2.4 Projektstandards

#### Code-Konventionen
- **Dart Style Guide** einhalten
- Funktionen dokumentieren mit `///` Kommentaren
- Fehlermeldungen mit `debugPrint()` für besseres Debugging
- `try-catch` Blöcke für alle asynchronen Operationen

#### State Management
- Verwendung von `StatefulWidget` mit `setState()`
- Unsaved Changes Detection mit `_hasUnsavedChanges` Flag
- `PopScope` für Back-Button-Handling

#### UI/UX Standards
- Material Design 3
- Primärfarbe: `Color(0xFFE65100)` (Orange)
- Responsive Layout für Mobile, Tablet und Desktop
- Loading-Indikatoren bei asynchronen Operationen
- Validierung von Formulareingaben
- Bestätigungsdialoge vor kritischen Aktionen

### 2.5 App zum Laufen bringen

**Schritt 3: App starten**
Das Projekt in Visual Studio Code aufmachen und im Terminal der folgende Befehl ausführen:
```bash
flutter run
```
Der bevorzügte Browser auswählen: 
[1]: Windows (windows)
[2]: Chrome (chrome)
[3]: Edge (edge)
```bash

```

## 3. Systemarchitektur

### 3.1 Architektur-Diagramm

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App (Frontend)                  │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │    Pages     │  │   Widgets    │  │    Models    │      │
│  │  (UI Layer)  │  │ (Components) │  │  (Data DTO)  │      │
│  └──────┬───────┘  └──────────────┘  └──────────────┘      │
│         │                                                     │
│  ┌──────▼──────────────────────────────────────────┐        │
│  │            Services Layer                        │        │
│  │  ┌────────────┐  ┌───────────────┐             │        │
│  │  │ Auth       │  │ Database      │             │        │
│  │  │ Service    │  │ Service       │             │        │
│  │  └─────┬──────┘  └───────┬───────┘             │        │
│  │        │                  │                      │        │
│  │        └──────────┬───────┘                      │        │
│  └───────────────────┼──────────────────────────────┘        │
│                      │                                        │
└──────────────────────┼────────────────────────────────────────┘
                       │
                       │ REST API / WebSocket
                       │
┌──────────────────────▼────────────────────────────────────────┐
│                    Supabase Backend                            │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ PostgreSQL   │  │    Auth      │  │   Storage    │        │
│  │   Database   │  │   Service    │  │   (Images)   │        │
│  │              │  │              │  │              │        │
│  │ • recipes    │  │ • JWT Tokens │  │ • Rezept-    │        │
│  │ • users      │  │ • RLS Rules  │  │   bilder     │        │
│  │ • ratings    │  │              │  │              │        │
│  │ • favorites  │  │              │  │              │        │
│  │ • week_plan  │  │              │  │              │        │
│  │ • shopping   │  │              │  │              │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
└─────────────────────────────────────────────────────────────────┘
                       │
                       │ HTTPS
                       │
┌──────────────────────▼────────────────────────────────────────┐
│              Externe APIs (Nutrition Service)                  │
│                                                                 │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐   │
│  │ USDA FoodData  │  │ LibreTranslate │  │   MyMemory    │   │
│  │   Central      │  │      API       │  │ Translation   │   │
│  │ (Nährwerte)    │  │  (DE↔EN)      │  │   (Fallback)  │   │
│  └────────────────┘  └────────────────┘  └───────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Kommunikation zwischen Systemen

#### 3.2.1 Flutter App ↔ Supabase

**Authentication Flow**
```
1. User Login → AuthService.signIn()
2. Supabase Auth → JWT Token generieren
3. Token speichern → supabase_flutter SDK
4. Alle API-Calls → Authorization Header mit JWT
```

**Datenbank-Operationen**
```dart
// Beispiel: Rezept erstellen
DatabaseService.createRecipe(recipe)
  → SupabaseClient.from('recipes').insert(...)
  → PostgreSQL INSERT
  → Row Level Security Check (user_id)
  → Response zurück an App
```

**Storage-Operationen**
```dart
// Beispiel: Bild hochladen
DatabaseService.uploadRecipeImage(bytes, fileName)
  → SupabaseClient.storage.from('recipe-images').uploadBinary(...)
  → Supabase Storage Bucket
  → Public URL generieren
  → URL in recipes.image_url speichern
```

#### 3.2.2 Flutter App ↔ USDA API

**Nährwertberechnung Flow**
```
1. User klickt "Nährwerte berechnen" in recipe_form_page
2. NutritionApiService.searchProductsOFF(ingredientName)
3. Automatische Übersetzung DE→EN:
   - Versuch 1: LibreTranslate API
   - Fallback: MyMemory API
   - Cache-Lookup für bereits übersetzte Begriffe
4. USDA API Request mit englischem Suchbegriff
5. Ergebnisse filtern (nur mit vollständigen Nährwerten)
6. Produktnamen parallel EN→DE übersetzen (für UI)
7. User wählt Produkt aus Dialog
8. Nährwerte pro Portion berechnen
9. Form-Controller befüllen
```

**API-Resilience**
- Retry-Mechanismus (max. 2 Versuche)
- Timeout nach 10 Sekunden
- Rate-Limiting Detection (HTTP 429)
- Graceful Degradation bei Übersetzungsfehlern

#### 3.2.3 Datenbank-Schema (Supabase PostgreSQL)

**Haupttabellen**
```sql
recipes (id, title, description, image_url, duration_minutes, 
         servings, difficulty, meal_type, owner_id, 
         average_rating, total_ratings, created_at)

profiles (id, username, diet_preference, created_at, updated_at)

ingredients (id, name)

recipe_ingredients (recipe_id, ingredient_id, quantity, unit)

recipe_steps (id, recipe_id, step_number, instruction)

tags (id, name)

recipe_tags (recipe_id, tag_id)

nutrition (id, recipe_id, calories, protein_g, carbs_g, fat_g)

ratings (id, recipe_id, user_id, score, comment, created_at)

user_favorites (id, user_id, recipe_id, created_at)

week_plan (id, user_id, week_start_date, day_of_week, 
           meal_type, recipe_id)

shopping_list (id, user_id, name, quantity, unit, 
               is_bought, created_at)
```

**Views für Performance**
```sql
-- Optimierte Abfrage mit Owner-Namen
recipes_with_owner AS (
  SELECT r.*, p.username as ownername
  FROM recipes r
  LEFT JOIN profiles p ON r.owner_id = p.id
)

-- Ratings mit User-Email
ratings_with_users AS (
  SELECT r.*, p.username as user_email
  FROM ratings r
  LEFT JOIN profiles p ON r.user_id = p.id
)
```

### 3.3 Security

**Row Level Security (RLS)**
- User kann nur eigene Rezepte bearbeiten/löschen
- User kann alle Rezepte lesen
- User kann nur eigene Favoriten/Ratings verwalten
- User kann nur eigenen Wochenplan/Einkaufsliste sehen

**Authentication**
- Email/Password via Supabase Auth
- JWT Token-basiert
- Automatische Session-Verwaltung
- Passwort-Anforderungen: Min. 6 Zeichen, 1 Großbuchstabe, 1 Zahl

---

## 4. Anforderungen (Umsetzung)

### 4.1 Obligatorische Anforderungen

| Anforderung | Status | Umsetzung |
|-------------|--------|-----------|
| **Benutzer-Authentifizierung** | ✅ Umgesetzt | Login, Registrierung, Logout über Supabase Auth (`login_page.dart`, `register_page.dart`) |
| **CRUD-Operationen für Rezepte** | ✅ Umgesetzt | Erstellen, Lesen, Bearbeiten, Löschen in `recipe_form_page.dart`, `database_service.dart` |
| **Bilder hochladen** | ✅ Umgesetzt | `image_picker` + Supabase Storage, Web & Mobile Support |
| **Rezeptsuche** | ✅ Umgesetzt | Suchleiste mit Titel-Filterung in `home.dart` |
| **Rezeptdetails anzeigen** | ✅ Umgesetzt | `recipe_detail_page.dart` mit allen Informationen |
| **Responsive Design** | ✅ Umgesetzt | GridView mit dynamischer `crossAxisCount` (1-3 Spalten) |
| **Datenpersistenz** | ✅ Umgesetzt | PostgreSQL via Supabase |
| **Fehlerbehandlung** | ✅ Umgesetzt | Try-catch Blöcke, SnackBars für User-Feedback |
| **Eingabevalidierung** | ✅ Umgesetzt | Form-Validierung in allen Formularen |

### 4.2 Optionale Anforderungen (Umgesetzt)

| Feature | Status | Beschreibung |
|---------|--------|--------------|
| **Bewertungssystem** | ✅ Umgesetzt | 5-Sterne-Bewertung + Kommentare, Durchschnitt wird berechnet (`rating_widget.dart`) |
| **Favoriten/Bookmarks** | ✅ Umgesetzt | Toggle-Funktion, separate Ansicht "Gespeichert" |
| **Tags/Kategorien** | ✅ Umgesetzt | FilterChips mit vordefiniertem Tag-System + Mahlzeitentyp |
| **Wochenplanung** | ✅ Umgesetzt | 7-Tage-Planer mit 3 Mahlzeiten, Navigation zwischen Wochen (`weeklyplan_page.dart`) |
| **Einkaufsliste** | ✅ Umgesetzt | Generierung aus Rezepten/Wochenplan, Checkbox für "gekauft", Bearbeiten, Teilen (`buy_list_page.dart`) |
| **Nährwertangaben** | ✅ Umgesetzt | Automatische Berechnung via USDA API mit Übersetzung, manuelle Eingabe möglich |
| **Schwierigkeitsgrad** | ✅ Umgesetzt | Enum: Einfach, Mittel, Schwer |
| **Zubereitungszeit** | ✅ Umgesetzt | Eingabe in Minuten, Filter nach Zeitbereichen |
| **Portionenanzahl** | ✅ Umgesetzt | Anpassbare Portionen, Nährwerte pro Portion |
| **Teilen-Funktion** | ✅ Umgesetzt | `share_plus` Package für System-Share (Text mit Link) |
| **Profilverwaltung** | ✅ Umgesetzt | Username, Ernährungspräferenz, Konto löschen (`profile_page.dart`) |
| **Unsaved Changes Detection** | ✅ Umgesetzt | Warnung beim Verlassen von Formularen mit ungespeicherten Änderungen |
| **Filter & Sortierung** | ✅ Umgesetzt | Nach Tags, Zeit, Mahlzeitentyp, Beliebtheit, Neueste, Meine Rezepte |

### 4.3 Nicht umgesetzte Features

| Feature | Grund |
|---------|-------|
| **Offline-Modus** | Zeitliche Einschränkungen, würde lokale Datenbank (Hive/SQLite) erfordern |
| **Social Features (Follower)** | Fokus lag auf Core-Funktionen, würde zusätzliche Tabellen erfordern |
| **Multi-Sprachen** | Nur deutsche UI, API-Übersetzung für Nährwerte implementiert |
| **Dark Mode** | Zeitliche Einschränkungen |
| **Push-Benachrichtigungen** | Nicht im Scope, würde Firebase/OneSignal erfordern |
| **Rezept-Import (URL)** | Web-Scraping komplex, rechtliche Bedenken |
| **Meal Prep Tracking** | Feature-Creep, optional für zukünftige Version |

### 4.4 Besondere Implementierungen

#### 4.4.1 USDA API Integration mit Auto-Translation
Die Nährwertberechnung ist vollautomatisch:
1. Deutsche Zutat → Automatische Übersetzung zu Englisch
2. USDA API Abfrage (nur Basis-Lebensmittel)
3. Parallele Übersetzung aller Produktnamen zurück zu Deutsch
4. User wählt aus übersetzter Liste
5. Berechnung pro Portion mit Einheiten-Konvertierung (g, ml, Stück, Teelöffel)
6. Fallback-Mechanismen für fehlende Übersetzungen

#### 4.4.2 Wochenplan mit Persistenz
- Speicherung pro `week_start_date` (Montag)
- Navigation zwischen Wochen ohne Datenverlust
- Unsaved Changes Warning beim Wechsel
- Darstellung mit Rezeptbildern und Meal-Indicators

#### 4.4.3 Intelligente Einkaufsliste
- Automatische Mengenaddition bei doppelten Zutaten
- Getrennte Anzeige: "Verwendete Produkte", "Übersprungen", "Nicht gefunden"
- Checkbox-Status persistent
- Einzelne Items bearbeitbar

---

## 5. Fazit

Der **RecipeShare** ist eine voll funktionsfähige Anwendung mit umfangreichen Features für die Rezeptverwaltung. Die Integration externer APIs (USDA, LibreTranslate) und die Nutzung von Supabase als Backend-as-a-Service ermöglichen eine moderne, skalierbare Architektur. 

**Stärken:**
- Vollständige CRUD-Funktionalität
- Automatische Nährwertberechnung mit Übersetzung
- Umfangreiche Zusatzfeatures (Wochenplan, Einkaufsliste)
- Responsive Design für alle Plattformen
- Robuste Fehlerbehandlung und User-Feedback

**Verbesserungspotential:**
- Offline-Support für bessere Nutzererfahrung ohne Internet
- Performance-Optimierung bei großen Rezeptsammlungen (Pagination)
- Erweiterte Social-Features (Teilen mit anderen Usern direkt in der App)

---

*Erstellt: Januar 2026*  
*Version: 1.0*