<div align="center">

# 🍳 RecipeShare

### Eine Cross-Platform Kochrezepte-Verwaltungs- und Austausch-App

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

**Entwickelt im Rahmen von Cross-Platform Development WiSe25/26**

</div>

---

## Inhaltsverzeichnis

1. [Projektübersicht](#1-projektübersicht)
2. [Technische Umsetzung](#2-technische-umsetzung)
3. [Systemarchitektur](#3-systemarchitektur)
4. [Anforderungen und Umsetzung](#4-anforderungen-und-umsetzung)
5. [Fazit](#5-fazit)

---

## 1. Projektübersicht

### 1.1 Was ist RecipeShare?

RecipeShare ist eine moderne mobile Anwendung zur Verwaltung und zum Austausch von Kochrezepten zwischen Benutzern. Die App kombiniert persönliche Rezeptverwaltung mit Community-Features und bietet eine umfassende Lösung für alle, die ihre Lieblingsrezepte organisieren und mit anderen teilen möchten.

### 1.2 Hauptfunktionen

<table>
<tr>
<td width="50%">

#### 📋 Rezeptverwaltung

- Vollständige CRUD-Funktionalität (Erstellen, Lesen, Bearbeiten, Löschen)
- Upload und Verwaltung von Rezeptbildern
- Kategorisierung durch Tags (z.B. Vegan, Glutenfrei, Vegetarisch)
- Automatische Nährwertberechnung mit USDA FoodData Central API

</td>
<td width="50%">

#### 👥 Social Features

- 5-Sterne-Bewertungssystem mit Kommentaren
- Teilen von Rezepten via Email, WhatsApp, Telegram
- Merkzettel-Funktion für Favoriten
- Entdecken von neuen und beliebten Rezepten der Community

</td>
</tr>
<tr>
<td width="50%">

#### 📅 Planungs-Tools

- Wochenplan zur Mahlzeitenplanung
- Automatische Einkaufsliste aus Rezeptzutaten
- Manuelle Bearbeitung und Status-Tracking der Einkaufsliste

</td>
<td width="50%">

#### 🔍 Erweiterte Suchfunktionen

- Suche nach Rezeptnamen, Zutaten und Tags
- Filterung nach Ernährungspräferenzen

</td>
</tr>
<tr>
<td colspan="2">

#### 👤 Benutzerverwaltung

- Sichere Authentifizierung (Registrierung/Anmeldung)
- Profilverwaltung mit Ernährungspräferenzen
- Personalisierte Rezeptvorschläge

</td>
</tr>
</table>

---

## 2. Technische Umsetzung

### 2.1 Technologie-Stack

<table>
<tr>
<td>

#### 📱 Frontend - Cross-Platform Mobile

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Material Design](https://img.shields.io/badge/Material_Design_3-757575?style=for-the-badge&logo=material-design&logoColor=white)

- Flutter/Dart für native iOS und Android Apps
- Material Design 3 für moderne UI
- StatefulWidget für State Management
- PopScope für Navigation mit Bestätigungsdialogen

</td>
</tr>
<tr>
<td>

#### ☁️ Backend - Cloud Infrastructure

![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

- Supabase als Backend-as-a-Service
- Authentication System
- Storage Buckets für Bildverwaltung

</td>
</tr>
<tr>
<td>

#### 🔌 Externe APIs und Services

![API](https://img.shields.io/badge/USDA_API-FF5722?style=for-the-badge&logo=api&logoColor=white)
![Translation](https://img.shields.io/badge/Translation_API-FF9800?style=for-the-badge&logo=googletranslate&logoColor=white)

- USDA FoodData Central API für Nährwertdaten
- LibreTranslate API für automatische DE↔EN Übersetzung
- MyMemory API als Fallback-Übersetzungsdienst

</td>
</tr>
</table>

### 2.2 Projektstruktur

```
recipeshare/
├── lib/
│   ├── main.dart                    # App-Einstiegspunkt
│   ├── models/                 
│   │   └── recipe.dart
│   ├── pages/                # Business Logic
│   │   ├── feature_extends/
│   │   │    ├── buy_list_page.dart
│   │   │    └── weeklyplan_page.dart
│   │   ├── Login:SignUp/
│   │   │    ├── login_page.dart
│   │   │    └── register_page.dart    
│   │   ├── Recipe/
│   │   │    ├── recipe_detail_page.dart
│   │   │    └── recipe_form_page.dart  
│   │   ├── home.dart
│   │   └── profile_page.dart
│   ├── supabase/               # Datenmodelle
│   │   ├── auth_service.dart
│   │   ├── database_service.dart
│   │   ├── nutrition_api_service.dart
│   │   └── supabase_client.dart
│   ├── widgets/               # Datenmodelle
│   │   ├── common_widgets.dart
│   │   ├── filter_bottom_sheet.dart
│   │   ├── rating_widget.dart
│   │   ├── recipe_card.dart    
│   │   ├── recipe_detail_items.dart
│   │   └──searchbart.dart
│   └─               
├── test/                         # Tests
├── pubspec.yaml               
└── README.md    
```

### 2.3 Installation und Setup

> **💡 Hinweis:** Diese Anleitung beschreibt die Installation für Entwickler.

#### Voraussetzungen

```diff
+ Visual Studio Code installieren
+ Flutter SDK von https://flutter.dev/docs/get-started/install installieren
```

#### Flutter-Version überprüfen

```bash
flutter --version
```

#### Projekt klonen und starten

```bash
# Repository klonen
git clone git@git.thm.de:xd-praktikum/ws-25/kochrezepte-app-ngamga.git

# Dependencies installieren
flutter pub get

# App starten
flutter run
```

#### Browser auswählen

```
1 → Windows (windows)
2 → Chrome (chrome)
3 → Edge (edge)
```

### 2.4 Verwendete Packages

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

### 2.5 Projektstandards

#### Code-Konventionen

- camelCase für Variablen und Funktionen
- PascalCase für Klassen
- Feature-basierte Organisation
- Dokumentation komplexer Logik

#### State Management

- StatefulWidget für UI-State
- Dirty-Flag System für ungespeicherte Änderungen
- PopScope für Navigation mit Bestätigungsdialogen

#### Error Handling

- Try-Catch-Blöcke für API-Calls
- Retry-Logik bei Netzwerkfehlern
- Benutzerfreundliche Fehlermeldungen

#### Performance-Optimierung

- Parallele API-Verarbeitung mit `Future.wait()`
- Caching für Übersetzungen
- Lazy Loading für Listen

---

## 3. Systemarchitektur

### 3.1 Architektur-Übersicht

Die RecipeShare-App folgt einer mehrschichtigen Architektur mit klarer Trennung von Präsentations-, Geschäftslogik- und Datenschicht.

```
╔═══════════════════════════════════════════════════════════╗
║         🎨 PRESENTATION LAYER (UI)                        ║
╠═══════════════════════════════════════════════════════════╣
║  Home Page │ Recipe Detail │ Recipe Form                 ║
║  Weekly Plan │ Buy List │ Profile                         ║
║  Login/Register Pages                                     ║
╚═══════════════════════════════════════════════════════════╝
                          ↕
╔═══════════════════════════════════════════════════════════╗
║         ⚙️ BUSINESS LOGIC LAYER                           ║
╠═══════════════════════════════════════════════════════════╣
║  DatabaseService │ AuthService                            ║
║  NutritionApiService │ TranslationService                 ║
║  StorageService                                           ║
╚═══════════════════════════════════════════════════════════╝
                          ↕
╔═══════════════════════════════════════════════════════════╗
║         💾 DATA LAYER                                     ║
╠═══════════════════════════════════════════════════════════╣
║  Supabase Backend:                                        ║
║  • PostgreSQL-Datenbank                                   ║
║  • Authentication System                                  ║
║  • Storage Buckets                                        ║
╚═══════════════════════════════════════════════════════════╝
                          ↕
╔═══════════════════════════════════════════════════════════╗
║         🌐 EXTERNAL SERVICES                              ║
╠═══════════════════════════════════════════════════════════╣
║  USDA FoodData Central API │ LibreTranslate API           ║
║  MyMemory API │ Share Plus Plugin                         ║
╚═══════════════════════════════════════════════════════════╝
```

### 3.2 Datenbank-Schema

#### profiles

- Speichert Benutzerprofile und Ernährungspräferenzen
- Felder: id, username, diet_preference, created_at, updated_at
- Relation: 1:N zu recipes, ratings, bookmarks

#### recipes

- Haupttabelle für Rezeptdaten
- Felder: id, user_id, title, description, difficulty, prep_time, servings, tags, image_url, created_at
- Relation: N:1 zu profiles, 1:N zu ingredients, instructions, ratings

#### ingredients

- Zutaten eines Rezepts mit Nährwertdaten
- Felder: id, recipe_id, name, quantity, unit, calories, protein, carbs, fat
- Relation: N:1 zu recipes

#### instructions

- Schritt-für-Schritt Anweisungen
- Felder: id, recipe_id, step_number, description
- Relation: N:1 zu recipes

#### ratings

- Bewertungen und Kommentare
- Felder: id, recipe_id, user_id, rating, comment, created_at
- Relation: N:1 zu recipes und profiles

#### bookmarks

- Gespeicherte Favoriten-Rezepte
- Felder: id, recipe_id, user_id, created_at
- Relation: N:1 zu recipes und profiles

#### weekly_plans

- Wochenplanung für Mahlzeiten
- Felder: id, user_id, recipe_id, day_of_week, created_at
- Relation: N:1 zu recipes und profiles

#### shopping_list

- Einkaufslisten-Einträge
- Felder: id, user_id, name, quantity, unit, is_bought
- Relation: N:1 zu profiles

### 3.3 Kommunikation zwischen Systemen

#### Mobile App ↔ Supabase Backend

- Protokoll: HTTPS REST API
- Datenaustausch: JSON-Format
- Real-time: Optional über Supabase Realtime

#### App ↔ USDA FoodData Central API

- Protokoll: HTTPS REST API
- Authentifizierung: API-Key
- Error Handling: Retry-Logik mit exponential backoff

#### App ↔ Übersetzungs-APIs

- Primär: LibreTranslate (Open-Source)
- Fallback: MyMemory API
- Cache-System: Lokales Caching häufiger Übersetzungen
- Performance: Parallele Verarbeitung mit `Future.wait()`

#### App ↔ Share Plus

- Integration: Native Platform-Integration
- Unterstützte Kanäle: Email, WhatsApp, Telegram, etc.
- Datenformat: Text oder strukturierte Daten

### 3.4 Wichtige Workflows

#### 🔄 Rezept erstellen mit Nährwertberechnung

```mermaid
graph LR
    A[1. Rezeptdaten eingeben] --> B[2. Übersetzung DE→EN]
    B --> C[3. USDA API Abfrage]
    C --> D[4. Nährwerte aggregieren]
    D --> E[5. Daten speichern]
    E --> F[6. Bild hochladen]
    F --> G[7. UI aktualisieren]
    style A fill:#FF5722
    style G fill:#4CAF50
```

<details>
<summary><b>Detaillierter Ablauf</b></summary>

1. Benutzer gibt Rezeptdaten ein (UI)
2. App sendet Zutatenliste an TranslationService
3. Parallele Übersetzung DE→EN für jede Zutat
4. NutritionApiService fragt USDA API ab
5. Aggregation der Nährwertdaten
6. DatabaseService speichert alles
7. StorageService lädt Bild hoch
8. UI wird aktualisiert

</details>

---

#### ⭐ Rezept bewerten

```mermaid
graph LR
    A[1. Rezept öffnen] --> B[2. Bewerten klicken]
    B --> C[3. Bewertungs-Dialog]
    C --> D[4. Prüfung]
    D --> E[5. Speichern]
    E --> F[6. Durchschnitt berechnen]
    F --> G[7. UI aktualisieren]
    style A fill:#FF5722
    style G fill:#4CAF50
```

<details>
<summary><b>Detaillierter Ablauf</b></summary>

1. Benutzer öffnet Rezept-Detailseite
2. Klick auf "Bewerten" Button
3. Bewertungs-Dialog erscheint (Sterne + optionaler Kommentar)
4. DatabaseService prüft, ob bereits bewertet wurde
5. UPDATE oder INSERT der Bewertung
6. Durchschnittsbewertung neu berechnen
7. UI aktualisiert Sterne-Anzeige

</details>

---

#### 📅 Wochenplan erstellen

```mermaid
graph LR
    A[1. Wochenplan öffnen] --> B[2. Tag auswählen]
    B --> C[3. Rezept wählen]
    C --> D[4. Speichern]
    D --> E[5. UI aktualisieren]
    E --> F[6. Einkaufsliste?]
    style A fill:#FF5722
    style F fill:#4CAF50
```

<details>
<summary><b>Detaillierter Ablauf</b></summary>

1. Benutzer öffnet Wochenplan-Seite
2. Klick auf "Rezept hinzufügen" für Tag
3. Rezept auswählen aus eigenen/Community/Merkzettel
4. DatabaseService: INSERT in weekly_plans
5. UI aktualisiert Wochenplan
6. Optional: Zutaten zu Einkaufsliste hinzufügen

</details>

---

#### 🛒 Einkaufsliste generieren

```mermaid
graph LR
    A[1. Einkaufsliste öffnen] --> B[2. Import klicken]
    B --> C[3. Rezepte laden]
    C --> D[4. Zutaten aggregieren]
    D --> E[5. Duplikate prüfen]
    E --> F[6. Items einfügen]
    F --> G[7. Liste anzeigen]
    style A fill:#FF5722
    style G fill:#4CAF50
```

<details>
<summary><b>Detaillierter Ablauf</b></summary>

1. Benutzer öffnet Einkaufsliste
2. Klick auf "Aus Wochenplan importieren"
3. DatabaseService lädt alle Rezepte aus weekly_plans
4. Zutaten aggregieren (gleiche Zutaten zusammenfassen)
5. Duplikate prüfen
6. Neue Items in shopping_list einfügen
7. UI zeigt aktualisierte Liste mit Gruppierung

</details>

### 3.5 Technische Herausforderungen und Lösungen

<table>
<tr>
<td width="50%">

#### ⚠️ Problem: API-Übersetzung

USDA API liefert nur englische Lebensmittel-Namen

</td>
<td width="50%">

#### ✅ Lösung

Automatische DE↔EN Übersetzung mit LibreTranslate + MyMemory Fallback und lokalem Cache

</td>
</tr>
<tr>
<td width="50%">

#### ⚠️ Problem: Nährwert-Performance

25+ sequenzielle API-Calls verursachten Ladezeiten von 30+ Sekunden

</td>
<td width="50%">

#### ✅ Lösung

Parallele Verarbeitung mit `Future.wait()` reduzierte Ladezeit auf 3-5 Sekunden

</td>
</tr>
<tr>
<td width="50%">

#### ⚠️ Problem: State Management

Tracking ungespeicherter Änderungen bei Rezept-Bearbeitung

</td>
<td width="50%">

#### ✅ Lösung

Dirty-Flag System mit `PopScope` für Bestätigungs-Dialoge

</td>
</tr>
</table>

---

## 4. Anforderungen und Umsetzung

### 4.1 Obligatorische Anforderungen

| Status | Anforderung | Beschreibung |
|:------:|-------------|--------------|
| ✅ | **CRUD von Rezepten** | Erstellen, Lesen, Bearbeiten und Löschen von Rezepten mit Bildern, Zutaten, Anweisungen und Metadaten |
| ✅ | **Verschlagwortung** | Kategorisierung durch Tags wie Vegan, Glutenfrei, Vegetarisch |
| ✅ | **Nährwertansicht** | Automatische Berechnung mit USDA API, Anzeige pro Rezept und pro Portion |
| ✅ | **Rezeptsuche** | Suche nach Namen, Zutaten und Tags mit Filterung nach Ernährungspräferenzen |
| ✅ | **Bewertungssystem** | 5-Sterne-Bewertung mit optionalen Kommentaren |
| ✅ | **Teilen-Funktion** | Teilen via Email |
| ✅ | **Benutzer-Authentifizierung** | Sichere Registrierung und Anmeldung mit Email/Passwort |

> **📊 Erfolgsquote:** 7/7 Anforderungen erfolgreich implementiert (100%)

### 4.2 Mögliche zukünftige Erweiterungen

#### Erweiterte Social Features

- Follower-System für Benutzer
- Rezept-Collections (Sammlungen)
- Personalisierte User Feeds

#### KI-Integration

- Intelligente Rezept-Empfehlungen
- Automatische Zutatenerkennung per Foto
- Generierung von Rezepten aus vorhandenen Zutaten

#### Offline-Modus

- Lokale Datenspeicherung mit SQLite
- Automatische Synchronisation
- Offline-Zugriff auf gespeicherte Rezepte

#### Erweiterte Analysen

- Nährwert-Tracking über Zeit
- Ernährungsstatistiken und Visualisierungen
- Zielerreichungs-Dashboard

#### Multi-Language Support

- Vollständige Internationalisierung
- Automatische Übersetzung aller App-Inhalte
- Mehrsprachige Rezepte

#### Smart Device Integration

- Anbindung an Smart Kitchen Appliances
- Sprachsteuerung

---

## 5. Fazit

### 5.1 Projekterfolge

> **🎯 RecipeShare demonstriert die Entwicklung einer vollständigen Cross-Platform Mobile App mit modernem Tech-Stack**

<table>
<tr>
<td width="50%">

**✅ Vollständige Anforderungserfüllung**

Alle obligatorischen und optionalen Anforderungen wurden implementiert

</td>
<td width="50%">

**🎨 Professionelles Design**

Moderne UI/UX mit Material Design 3 und durchdachten Workflows

</td>
</tr>
<tr>
<td width="50%">

**🔗 Robuste Backend-Integration**

Zuverlässige Anbindung an Supabase mit PostgreSQL

</td>
<td width="50%">

**🚀 Innovative API-Integration**

Intelligente Kombination von USDA, Übersetzungs-APIs und Caching

</td>
</tr>
<tr>
<td width="50%">

**⚡ Performance-Optimierung**

Parallele Verarbeitung reduzierte API-Ladezeiten um 85%

</td>
<td width="50%">

**🏗️ Skalierbare Architektur**

Klare Trennung von Präsentations-, Business- und Data-Layer

</td>
</tr>
</table>

### 5.2 Gewonnene Erkenntnisse

#### Flutter State Management und Navigation

- Effektive Nutzung von StatefulWidget für reaktive UI
- Implementation von Dirty-Flag Systemen für komplexe Workflows
- Moderne Navigation mit PopScope für bessere UX

#### API-Integration und Error Handling

- Robuste Fehlerbehandlung mit Retry-Logik
- Fallback-Strategien für externe Dienste
- Cache-Implementierung für Performance

#### Datenbank-Design und Supabase

- Normalisiertes Schema für relationale Daten
- Effiziente Queries mit PostgreSQL
- Integration von Authentication und Storage

#### Performance-Optimierung

- Parallele API-Verarbeitung mit `Future.wait()`
- Lazy Loading für große Datensätze
- Responsive Design für verschiedene Geräte

### 5.3 Team

<div align="center">

**Entwickelt von:**

| Name | Rolle |
|------|-------|
| Ange Dongmo | Developer |
| Hylarie Nzeye | Developer |
| Manuela Djomkam | Developer |
| Ken Ulrich Nya | Developer |

**Zeitraum:** Wintersemester 2025/26

</div>

---

<div align="center">

**RecipeShare** - Kochrezepte verwalten, entdecken und teilen.

![RecipeShare](https://img.shields.io/badge/RecipeShare-FF5722?style=for-the-badge&logo=flutter&logoColor=white)

</div>