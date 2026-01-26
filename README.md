<div align="center">

# 🍳 RecipeShare
### Projektdokumentation

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
<img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase"/>
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>

**Eine Cross-Platform Kochrezepte-Verwaltungs- und Austausch-App**

*Entwickelt im Rahmen von Cross-Platform Development WiSe25/26*

</div>

---

## 📋 Inhaltsverzeichnis

<table>
<tr>
<td width="50%">

**📖 Hauptkapitel**
1. [🎯 Projektübersicht](#-projektübersicht)
2. [🛠 Technische Umsetzung](#-technische-umsetzung)
3. [🏗 Systemarchitektur](#-systemarchitektur)

</td>
<td width="50%">

**📊 Details**
4. [✅ Anforderungen & Umsetzung](#-anforderungen--umsetzung)
5. [🎓 Fazit](#-fazit)

</td>
</tr>
</table>

---

<div align="center">

## 🎯 Projektübersicht

</div>

### 💡 Was ist RecipeShare?

> RecipeShare ist eine moderne mobile Anwendung zur Verwaltung und zum Austausch von Kochrezepten zwischen Benutzern. Die App kombiniert persönliche Rezeptverwaltung mit Community-Features und bietet eine umfassende Lösung für alle, die ihre Lieblingsrezepte organisieren und mit anderen teilen möchten.

<br>

### ⭐ Hauptfunktionen

<table>
<tr>
<td width="50%" valign="top">

#### 📝 Rezeptverwaltung
- ✅ Vollständige CRUD-Funktionalität (Erstellen, Lesen, Bearbeiten, Löschen)
- 🖼️ Upload und Verwaltung von Rezeptbildern
- 🏷️ Kategorisierung durch Tags (z.B. Vegan, Glutenfrei, Vegetarisch)
- 🥗 Automatische Nährwertberechnung mit USDA FoodData Central API

#### 🌐 Social Features
- ⭐ 5-Sterne-Bewertungssystem mit Kommentaren
- 📤 Teilen von Rezepten via Email, WhatsApp, Telegram
- 💾 Merkzettel-Funktion für Favoriten
- 🔍 Entdecken von neuen und beliebten Rezepten der Community

</td>
<td width="50%" valign="top">

#### 📅 Planungs-Tools
- 📆 Wochenplan zur Mahlzeitenplanung
- 🛒 Automatische Einkaufsliste aus Rezeptzutaten
- ✏️ Manuelle Bearbeitung und Status-Tracking der Einkaufsliste

#### 🔎 Erweiterte Suchfunktionen
- 🔤 Suche nach Rezeptnamen, Zutaten und Tags
- 🎯 Filterung nach Ernährungspräferenzen

#### 👤 Benutzerverwaltung
- 🔐 Sichere Authentifizierung (Registrierung/Anmeldung)
- 👥 Profilverwaltung mit Ernährungspräferenzen
- 💡 Personalisierte Rezeptvorschläge

</td>
</tr>
</table>

---

<div align="center">

## 🛠 Technische Umsetzung

</div>

### 🔧 Technologie-Stack

<table>
<tr>
<td width="33%" align="center" valign="top">

#### 📱 Frontend
**Cross-Platform Mobile**

<img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter"/>
<img src="https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart"/>
<img src="https://img.shields.io/badge/Material_Design_3-757575?style=flat-square&logo=material-design&logoColor=white" alt="Material Design"/>

</td>
<td width="33%" align="center" valign="top">

#### ☁️ Backend
**Cloud Infrastructure**

<img src="https://img.shields.io/badge/Supabase-3ECF8E?style=flat-square&logo=supabase&logoColor=white" alt="Supabase"/>
<img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white" alt="PostgreSQL"/>
<img src="https://img.shields.io/badge/Authentication-FF6B6B?style=flat-square&logo=auth0&logoColor=white" alt="Auth"/>

</td>
<td width="33%" align="center" valign="top">

#### 🔌 APIs & Services
**External Integrations**

<img src="https://img.shields.io/badge/USDA_API-4A9F3A?style=flat-square&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAA7AAAAOwBeShxvQAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAEBSURBVCiRY2AYBaNgFIyCYQ4YGBj+/2dg+M/AwPAfCBgYGBhANP9/kDwDAwMDw///DAxAfmD8n+E/Az8DA0NAQAADAwMDA8N/hv9fvnxhYGBgYPgPxEACGBgY/jMwMDAwMDAwMPxnYPj/9+/f/wz//wMxEP8H4v9fvnxhAKr5z8DA8P/v379A9h8GBgaG/0D8/8uXLwz/gfg/AwPDfyD+DwQMDAwM/4H4PwMDA8N/IP4PxP+B+D8QMwDV/Afh/0D8H4j/A/F/IP4PxP+B+D8Q/wfi/0D8H4j/A/F/IP4PxP+B+D8Q/wfi/0D8H4j/A/F/IP4PxP+B+D8QAwCMvTDxQs3vEwAAAABJRU5ErkJggg==" alt="USDA"/>
<img src="https://img.shields.io/badge/Translation_APIs-4285F4?style=flat-square&logo=google-translate&logoColor=white" alt="Translation"/>
<img src="https://img.shields.io/badge/Share_Plus-25D366?style=flat-square&logo=whatsapp&logoColor=white" alt="Share"/>

</td>
</tr>
</table>

<br>

#### 📱 Frontend - Cross-Platform Mobile

<blockquote>

**Flutter/Dart**
- **Version**: Flutter SDK (aktuell zum Entwicklungszeitpunkt)
- **Beschreibung**: Google's UI-Framework für native iOS und Android Apps aus einer gemeinsamen Codebasis
- **Verwendung**: Komplette UI-Implementierung mit Material Design 3

**State Management**
- **Technologie**: StatefulWidget
- **Verwendung**: Reaktive UI-Updates bei Datenänderungen, Dirty-Flag System für Unsaved Changes

**UI-Komponenten**
- Material Design 3 für moderne, konsistente Benutzeroberfläche
- Responsive Design mit `MediaQuery` und `LayoutBuilder`
- PopScope (Flutter 3.12+) für Bestätigungs-Dialoge

</blockquote>

#### ☁️ Backend - Cloud-basierte Infrastruktur

<blockquote>

**Supabase**
- **Beschreibung**: Open-Source Firebase-Alternative mit PostgreSQL-Datenbank
- **Komponenten**:
  - PostgreSQL-Datenbank für strukturierte Datenspeicherung
  - Authentication für Benutzer-Management mit Email/Passwort
  - Storage für Cloud-Speicher von Rezeptbildern mit öffentlichen URLs

</blockquote>

#### 🔌 Externe APIs & Services

<blockquote>

**USDA FoodData Central API**
- **Zweck**: Nährwertdaten (Kalorien, Protein, Kohlenhydrate, Fett)
- **Integration**: Automatische Berechnung mit Retry-Logik und Error Handling

**Übersetzungs-APIs**
- **LibreTranslate** (primär): Automatische DE↔EN Übersetzung für Zutatensuche
- **MyMemory** (Fallback): Alternative bei LibreTranslate-Ausfall
- **Optimierung**: Cache-System für verbesserte Performance

**Share Plus**
- **Beschreibung**: Flutter-Plugin zum plattformübergreifenden Teilen
- **Verwendung**: Teilen von Rezepten und Einkaufslisten via Email/Messenger

</blockquote>

---

### 💻 RecipeShare Projekt einrichten und ausführen


**1- VS Code** installieren.

**2- Flutter SDK** über https://flutter.dev/docs/get-started/install installieren.

```bash
# Flutter Version überprüfen
flutter --version
```

**3- Projekt lokal** ziehen.
```bash
# Repository klonen
git clone git@git.thm.de:xd-praktikum/ws-25/kochrezepte-app-ngamga.git
```

Das Projekt in Visual Studio Code aufmachen und im Terminal folgende Befehle ausführen:

```bash 
flutter pub get 
``` 
um  Flutter-Abhängigkeiten installieren und danach,

```bash 
flutter run
```
zum Laufen der App. 

Der bevorzügte Browser auswählen:
[1]: Windows (windows)
[2]: Chrome (chrome)
[3]: Edge (edge)

**4- Registrierung/Anmeldung**
Der Registrierungsprozess beginnt mit dem Start der Anwendung und der Anzeige des Anmelde-Screens. Dort gibt der Benutzer seine E-Mail-Adresse, einen Benutzernamen, ein Passwort inklusive Passwortbestätigung ein sowie seine Ernährungspräferenz. Anschließend werden die Eingaben validiert. Nachdem der Benutzer auf den Button „Registrieren“ klickt, wird ein API-Aufruf an Supabase Auth ausgeführt. Eine E-Mail zur Verifizierung der Adresse wird versendet. Danach erfolgt die automatische Erstellung des Benutzerprofils und der Benutzer wird zum Home-Screen weitergeleitet. Der Registrierungsprozess ist damit abgeschlossen und der Benutzer ist eingeloggt.

Wie Rezepte erstellt werden, wird im Abschnitt "Datenfluss Beispiele" beschrieben. Dort werden 
weitere Worklows dargestellt.


#### Verwendete Packages (pubspec.yaml)

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

---

### 📁 Projektstruktur

```
📦 recipeshare/
├── 📂 lib/
│   ├── 📄 main.dart                      # App-Einstiegspunkt
│   ├── 📂 pages/                         # UI-Screens
│   │   ├── 🏠 home_page.dart
│   │   ├── 📋 recipe_detail_page.dart
│   │   ├── ✏️ recipe_form_page.dart
│   │   ├── 📅 weekly_plan_page.dart
│   │   ├── 🛒 buy_list_page.dart
│   │   ├── 👤 profile_page.dart
│   │   ├── 🔐 login_page.dart
│   │   └── 📝 register_page.dart
│   ├── 📂 services/                      # Business Logic
│   │   ├── 💾 database_service.dart
│   │   ├── 🔑 auth_service.dart
│   │   └── 🥗 nutrition_api_service.dart
│   ├── 📂 models/                        # Datenmodelle
│   │   ├── 📄 recipe.dart
│   │   ├── 🥕 ingredient.dart
│   │   ├── 📝 instruction.dart
│   │   ├── ⭐ rating.dart
│   │   └── 👤 profile.dart
│   └── 📂 widgets/                       # Wiederverwendbare Komponenten
├── 📂 assets/                            # Bilder, Fonts, etc.
├── 📂 test/                              # Unit und Widget Tests
├── 📄 pubspec.yaml                       # Projekt-Konfiguration
└── 📄 README.md
```

---

### 📏 Projektstandards

<table>
<tr>
<td width="50%" valign="top">

#### 💼 Code-Konventionen
- `camelCase` für Variablen
- `PascalCase` für Klassen
- Feature-basierte Organisation
- Dokumentation komplexer Logik

#### 🎯 State Management
- StatefulWidget für UI-State
- Dirty-Flag System für ungespeicherte Änderungen
- PopScope für Navigation mit Bestätigungsdialogen

</td>
<td width="50%" valign="top">

#### ⚠️ Error Handling
- Try-Catch-Blöcke für API-Calls
- Retry-Logik bei Netzwerkfehlern
- User-freundliche Fehlermeldungen

#### ⚡ Performance-Optimierung
- Parallele API-Verarbeitung mit `Future.wait()`
- Caching für Übersetzungen
- Lazy Loading für Listen

</td>
</tr>
</table>

---


<div align="center">

## 🏗 Systemarchitektur

</div>

### 🎨 Architektur-Übersicht

> Die RecipeShare-App folgt einer mehrschichtigen Architektur mit klarer Trennung von Präsentations-, Geschäftslogik- und Datenschicht.

<br>

```
╔═══════════════════════════════════════════════════════════════════╗
║                    📱 PRESENTATION LAYER (UI)                      ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  🏠 Home Page              📋 Recipe Detail         ✏️ Recipe Form ║
║  (Neue/Beliebte Rezepte)   (Anzeige & Bewertung)   (Erstellen)   ║
║                                                                    ║
║  📅 Weekly Plan            🛒 Buy List             👤 Profile      ║
║  (Wochenplanung)           (Einkaufsliste)         (Benutzerprofil)║
║                                                                    ║
║  🔐 Login/Register Pages                                          ║
║  (Authentifizierung)                                              ║
║                                                                    ║
╚═══════════════════════════════════════════════════════════════════╝
                                  ⇅
╔═══════════════════════════════════════════════════════════════════╗
║                    ⚙️ BUSINESS LOGIC LAYER                         ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  💾 DatabaseService          🔑 AuthService                       ║
║  (CRUD-Operationen)          (Benutzer-Management)                ║
║                                                                    ║
║  🥗 NutritionApiService      🌐 TranslationService                ║
║  (Nährwert-Berechnung)       (DE↔EN Übersetzung)                 ║
║                                                                    ║
║  📤 StorageService                                                ║
║  (Bild-Upload)                                                    ║
║                                                                    ║
╚═══════════════════════════════════════════════════════════════════╝
                                  ⇅
╔═══════════════════════════════════════════════════════════════════╗
║                        💾 DATA LAYER                               ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  ☁️ Supabase Backend:                                             ║
║                                                                    ║
║  • 🗄️ PostgreSQL-Datenbank                                        ║
║  • 🔐 Authentication System                                       ║
║  • 📁 Storage Buckets (Bilder)                                    ║
║                                                                    ║
╚═══════════════════════════════════════════════════════════════════╝
                                  ⇅
╔═══════════════════════════════════════════════════════════════════╗
║                      🌐 EXTERNAL SERVICES                          ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  🥗 USDA FoodData Central API    🌍 LibreTranslate API            ║
║  (Nährwertdaten)                  (Übersetzung)                   ║
║                                                                    ║
║  🔄 MyMemory API                  📤 Share Plus Plugin            ║
║  (Fallback-Übersetzung)           (Teilen-Funktionalität)         ║
║                                                                    ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

### 🗄️ Datenbank-Schema (Supabase PostgreSQL)

<table>
<tr>
<td width="50%" valign="top">

#### 👤 profiles
> Speichert Benutzerprofile und Ernährungspräferenzen

**Felder:**
- `id` 🔑
- `username` 
- `diet_preference` 
- `created_at` 📅
- `updated_at` 📅

**Relation:** 1:N zu recipes, ratings, bookmarks

---

#### 🍳 recipes
> Haupttabelle für Rezeptdaten

**Felder:**
- `id` 🔑
- `user_id` 🔗
- `title` 
- `description` 
- `difficulty` 
- `prep_time` ⏱️
- `servings` 
- `tags` 🏷️
- `image_url` 🖼️
- `created_at` 📅

**Relation:** N:1 zu profiles, 1:N zu ingredients, instructions, ratings

---

#### 🥕 ingredients
> Zutaten eines Rezepts mit Nährwertdaten

**Felder:**
- `id` 🔑
- `recipe_id` 🔗
- `name` 
- `quantity` 
- `unit` 
- `calories` 
- `protein` 
- `carbs` 
- `fat` 

**Relation:** N:1 zu recipes

---

#### 📝 instructions
> Schritt-für-Schritt Anweisungen

**Felder:**
- `id` 🔑
- `recipe_id` 🔗
- `step_number` 
- `description` 

**Relation:** N:1 zu recipes

</td>
<td width="50%" valign="top">

#### ⭐ ratings
> Bewertungen und Kommentare

**Felder:**
- `id` 🔑
- `recipe_id` 🔗
- `user_id` 🔗
- `rating` 
- `comment` 💬
- `created_at` 📅

**Relation:** N:1 zu recipes und profiles

---

#### 💾 bookmarks
> Gespeicherte Favoriten-Rezepte

**Felder:**
- `id` 🔑
- `recipe_id` 🔗
- `user_id` 🔗
- `created_at` 📅

**Relation:** N:1 zu recipes und profiles

---

#### 📅 weekly_plans
> Wochenplanung für Mahlzeiten

**Felder:**
- `id` 🔑
- `user_id` 🔗
- `recipe_id` 🔗
- `day_of_week` 
- `created_at` 📅

**Relation:** N:1 zu recipes und profiles

---

#### 🛒 shopping_list
> Einkaufslisten-Einträge

**Felder:**
- `id` 🔑
- `user_id` 🔗
- `name` 
- `quantity` 
- `unit` 
- `is_bought` ✅

**Relation:** N:1 zu profiles

</td>
</tr>
</table>

---

### 🔄 Kommunikation zwischen Systemen

### 🔄 Kommunikation zwischen Systemen

<table>
<tr>
<td width="50%" valign="top">

#### 📱 → ☁️ Mobile App ↔ Supabase Backend
> **Protokoll:** HTTPS REST API  
> **Datenaustausch:** JSON-Format  
> **Real-time:** Optional über Supabase Realtime für Live-Updates

---

#### 📱 → 🥗 App ↔ USDA FoodData Central API
> **Protokoll:** HTTPS REST API  
> **Authentifizierung:** API-Key  
> **Datenfluss:** App → Translation → USDA API → Nährwertdaten → App  
> **Error Handling:** Retry-Logik mit exponential backoff

</td>
<td width="50%" valign="top">

#### 📱 → 🌍 App ↔ Übersetzungs-APIs
> **Primär:** LibreTranslate (Open-Source, selbst-gehostet möglich)  
> **Fallback:** MyMemory API bei LibreTranslate-Ausfall  
> **Cache-System:** Lokales Caching häufiger Übersetzungen  
> **Performance:** Parallele Verarbeitung mit `Future.wait()`

---

#### 📱 → 📤 App ↔ Share Plus
> **Integration:** Native Platform-Integration  
> **Unterstützte Kanäle:** Email, 
> **Datenformat:** Text (Rezept) oder strukturierte Daten (Einkaufsliste)

</td>
</tr>
</table>

---

### 📊 Datenfluss-Beispiele

<table>
<tr>
<td width="50%" valign="top">

#### 🍳 Rezept erstellen mit Nährwertberechnung
```
1️⃣ Benutzer gibt Rezeptdaten ein (UI)
      ↓
2️⃣ App sendet Zutatenliste an TranslationService
      ↓
3️⃣ Parallele Übersetzung DE→EN für jede Zutat
      ↓
4️⃣ NutritionApiService fragt USDA API ab
      ↓
5️⃣ Aggregation der Nährwertdaten
      ↓
6️⃣ DatabaseService speichert alles
      ↓
7️⃣ StorageService lädt Bild hoch
      ↓
8️⃣ UI wird aktualisiert ✅
```

</td>
<td width="50%" valign="top">

#### 🔍 Rezepte entdecken
```
1️⃣ Benutzer öffnet "Neue/Beliebte Rezepte"
      ↓
2️⃣ DatabaseService lädt Rezepte basierend auf:
    • Ernährungspräferenzen
    • Erstellungsdatum / Bewertung
      ↓
3️⃣ Bilder von Supabase Storage laden
      ↓
4️⃣ Durchschnittliche Bewertung berechnen
      ↓
5️⃣ UI zeigt gefilterte Liste ✅
```

</td>
</tr>
</table>

<table>
<tr>
<td width="50%" valign="top">

#### ⭐ Rezept bewerten
```
1️⃣ Benutzer öffnet Rezept-Detailseite
      ↓
2️⃣ Klick auf "Bewerten" Button
      ↓
3️⃣ Bewertungs-Dialog erscheint
    • Sterne auswählen (1-5)
    • Optional: Kommentar eingeben
      ↓
4️⃣ DatabaseService prüft:
    • Hat Benutzer bereits bewertet?
    • Falls ja: UPDATE, sonst: INSERT
      ↓
5️⃣ Bewertung in DB speichern
      ↓
6️⃣ Durchschnittsbewertung neu berechnen
      ↓
7️⃣ UI aktualisiert Sterne-Anzeige ✅
```

</td>
<td width="50%" valign="top">

#### 💾 Rezept zu Merkzettel hinzufügen
```
1️⃣ Benutzer klickt Bookmark-Icon
      ↓
2️⃣ AuthService prüft:
    • Ist Benutzer eingeloggt?
      ↓
3️⃣ DatabaseService prüft:
    • Bereits im Merkzettel?
      ↓
4️⃣ Falls NEIN:
    • INSERT in bookmarks-Tabelle
    • Icon wird gefüllt
      ↓
5️⃣ Falls JA:
    • DELETE aus bookmarks-Tabelle
    • Icon wird ungefüllt
      ↓
6️⃣ Erfolgs-Toast anzeigen ✅
```

</td>
</tr>
</table>

<table>
<tr>
<td width="50%" valign="top">

#### 📅 Rezept zum Wochenplan hinzufügen
```
1️⃣ Benutzer öffnet Wochenplan-Seite
      ↓
2️⃣ Klick auf "Rezept hinzufügen" für Tag
      ↓
3️⃣ Rezeptsuche-Dialog öffnet
    • Eigene Rezepte
    • Community-Rezepte
    • Merkzettel
      ↓
4️⃣ Rezept auswählen
      ↓
5️⃣ DatabaseService:
    • INSERT in weekly_plans
    • recipe_id + user_id + day_of_week
      ↓
6️⃣ UI aktualisiert Wochenplan
      ↓
7️⃣ Optional: Zutaten zu Einkaufsliste ✅
```

</td>
<td width="50%" valign="top">

#### 🛒 Einkaufsliste generieren
```
1️⃣ Benutzer öffnet Einkaufsliste
      ↓
2️⃣ Klick auf "Aus Wochenplan importieren"
      ↓
3️⃣ DatabaseService lädt:
    • Alle Rezepte aus weekly_plans
    • Zugehörige Zutaten (ingredients)
      ↓
4️⃣ Zutaten aggregieren:
    • Gleiche Zutaten zusammenfassen
    • Mengen addieren
      ↓
5️⃣ Duplikate aus vorhandener Liste prüfen
      ↓
6️⃣ Neue Items in shopping_list einfügen
      ↓
7️⃣ UI zeigt aktualisierte Liste
      ↓
8️⃣ Gruppierung nach Kategorien ✅
```

</td>
</tr>
</table>

<table>
<tr>
<td width="50%" valign="top">

#### 🔎 Rezeptsuche mit Filtern
```
1️⃣ Benutzer gibt Suchbegriff ein
      ↓
2️⃣ Optional: Filter auswählen
    • Tags (Vegan, Glutenfrei, etc.)
    • Schwierigkeitsgrad
    • Zubereitungszeit
      ↓
3️⃣ DatabaseService erstellt Query:
    • LIKE-Suche auf title
    • ILIKE-Suche auf ingredients
    • WHERE-Filter für tags
      ↓
4️⃣ Suche in recipes + ingredients
      ↓
5️⃣ Ergebnisse nach Relevanz sortieren
      ↓
6️⃣ Bilder lazy-loaden
      ↓
7️⃣ UI zeigt Suchergebnisse ✅
```

</td>
<td width="50%" valign="top">

#### 📤 Rezept teilen
```
1️⃣ Benutzer öffnet Rezept-Detailseite
      ↓
2️⃣ Klick auf "Teilen" Button
      ↓
3️⃣ Share-Dialog erscheint:
    • Email
    • WhatsApp
    • Telegram
    • Mehr...
      ↓
4️⃣ Plattform auswählen (z.B. WhatsApp)
      ↓
5️⃣ App generiert Share-Text:
    • Rezept-Titel
    • Zutaten-Liste
    • Anweisungen
    • App-Link
      ↓
6️⃣ Share Plus Plugin öffnet WhatsApp
      ↓
7️⃣ Nachricht vorausgefüllt ✅
```

</td>
</tr>
</table>

<table>
<tr>
<td width="50%" valign="top">

#### ✏️ Rezept bearbeiten
```
1️⃣ Benutzer öffnet eigenes Rezept
      ↓
2️⃣ Klick auf "Bearbeiten" Button
      ↓
3️⃣ Rezept-Formular mit Daten vorausfüllen
      ↓
4️⃣ Benutzer ändert Daten:
    • Titel, Beschreibung
    • Zutaten hinzufügen/löschen
    • Schritte ändern
    • Neues Bild hochladen
      ↓
5️⃣ Dirty-Flag-System erkennt Änderungen
      ↓
6️⃣ Klick auf "Speichern"
      ↓
7️⃣ DatabaseService:
    • UPDATE recipes
    • DELETE alte ingredients
    • INSERT neue ingredients
    • UPDATE StorageService (falls Bild neu)
      ↓
8️⃣ Nährwerte neu berechnen
      ↓
9️⃣ UI zur Detail-Seite ✅
```

</td>
<td width="50%" valign="top">

#### 🗑️ Rezept löschen
```
1️⃣ Benutzer öffnet eigenes Rezept
      ↓
2️⃣ Klick auf "Löschen" Button
      ↓
3️⃣ Bestätigungs-Dialog erscheint:
    "Rezept wirklich löschen?"
    • Abbrechen
    • Löschen
      ↓
4️⃣ Klick auf "Löschen" bestätigen
      ↓
5️⃣ DatabaseService:
    • DELETE aus recipes (CASCADE)
    • Automatisch gelöscht:
      - ingredients
      - instructions
      - ratings
      - bookmarks
      - weekly_plans
      ↓
6️⃣ StorageService:
    • Rezept-Bild löschen
      ↓
7️⃣ UI zur Home-Screen
      ↓
8️⃣ Toast: "Rezept gelöscht" ✅
```

</td>
</tr>
</table>

<table>
<tr>
<td width="50%" valign="top">

#### 👤 Profil aktualisieren
```
1️⃣ Benutzer öffnet Profil-Seite
      ↓
2️⃣ Klick auf "Profil bearbeiten"
      ↓
3️⃣ Formular mit aktuellen Daten:
    • Benutzername
    • Ernährungspräferenz
    • Email (nicht änderbar)
      ↓
4️⃣ Änderungen vornehmen
      ↓
5️⃣ Validierung:
    • Username eindeutig?
    • 3-20 Zeichen?
      ↓
6️⃣ DatabaseService:
    • UPDATE profiles
    • updated_at = NOW()
      ↓
7️⃣ App-State aktualisieren
      ↓
8️⃣ Toast: "Profil aktualisiert" ✅
```

</td>
<td width="50%" valign="top">

#### 🔐 Passwort ändern
```
1️⃣ Benutzer öffnet Profil-Seite
      ↓
2️⃣ Klick auf "Passwort ändern"
      ↓
3️⃣ Dialog mit Feldern:
    • Aktuelles Passwort
    • Neues Passwort
    • Passwort bestätigen
      ↓
4️⃣ Validierung:
    • Aktuelles PW korrekt?
    • Neues PW erfüllt Anforderungen?
    • PW-Bestätigung stimmt überein?
      ↓
5️⃣ AuthService:
    • Supabase.auth.updateUser()
      ↓
6️⃣ Alle Sessions außer aktueller beenden
      ↓
7️⃣ Bestätigungs-Email senden
      ↓
8️⃣ Toast: "Passwort geändert" ✅
```

</td>
</tr>
</table>

<table>
<tr>
<td width="50%" valign="top">

#### 📊 Beliebte Rezepte laden
```
1️⃣ Benutzer öffnet "Beliebte Rezepte"
      ↓
2️⃣ Zeitfilter auswählen:
    • Diese Woche
    • Dieser Monat
    • Dieses Jahr
      ↓
3️⃣ DatabaseService Query:
    • JOIN recipes + ratings
    • WHERE created_at >= filter_date
    • GROUP BY recipe_id
    • ORDER BY AVG(rating) DESC
      ↓
4️⃣ Ernährungspräferenzen filtern
      ↓
5️⃣ Top 20 Rezepte laden
      ↓
6️⃣ Bilder parallel laden
      ↓
7️⃣ UI zeigt sortierte Liste ✅
```

</td>
<td width="50%" valign="top">

#### 🆕 Neue Rezepte laden
```
1️⃣ Benutzer öffnet "Neue Rezepte"
      ↓
2️⃣ DatabaseService Query:
    • SELECT * FROM recipes
    • WHERE user_id != current_user
    • ORDER BY created_at DESC
      ↓
3️⃣ Ernährungspräferenz-Filter:
    • IF user.diet_preference EXISTS
    • FILTER BY tags CONTAINS preference
      ↓
4️⃣ Pagination: Limit 20, Offset 0
      ↓
5️⃣ Bilder lazy-loaden (on scroll)
      ↓
6️⃣ Infinite Scroll:
    • Bei Scroll-Ende: Offset += 20
      ↓
7️⃣ UI zeigt chronologische Liste ✅
```

</td>
</tr>
</table>

<table>
<tr>
<td width="50%" valign="top">

#### 🛒 Einkaufsliste abhaken
```
1️⃣ Benutzer öffnet Einkaufsliste
      ↓
2️⃣ Klick auf Checkbox bei Item
      ↓
3️⃣ Checkbox-Status toggle:
    • is_bought = !is_bought
      ↓
4️⃣ DatabaseService:
    • UPDATE shopping_list
    • SET is_bought = new_value
    • WHERE id = item_id
      ↓
5️⃣ UI-Update:
    • Durchgestrichener Text (wenn checked)
    • Item nach unten verschieben
      
```

</td>
<td width="50%" valign="top">

#### 📤 Einkaufsliste teilen
```
1️⃣ Benutzer öffnet Einkaufsliste
      ↓
2️⃣ Klick auf "Teilen" Button
      ↓
3️⃣ DatabaseService lädt alle Items:
    • SELECT * FROM shopping_list
    • WHERE user_id = current_user
    • ORDER BY is_bought ASC
      ↓
4️⃣ Text formatieren:
    • "Einkaufsliste - RecipeShare"
    • "[ ] Zutat 1 - 200g"
    • "[ ] Zutat 2 - 3 Stück"
    • "[x] Zutat 3 - 1 Liter"
      ↓
5️⃣ Share-Dialog öffnen
      ↓
6️⃣ Plattform auswählen
      ↓
7️⃣ Share Plus sendet Text ✅
```

</td>
</tr>
</table>

<table>
<tr>
<td width="50%" valign="top">

#### 🔄 Session-Refresh
```
1️⃣ App startet / wird fortgesetzt
      ↓
2️⃣ AuthService prüft:
    • Existiert gespeicherte Session?
      ↓
3️⃣ Token-Validierung:
    • Access Token noch gültig?
      ↓
4️⃣ Falls ABGELAUFEN:
    • Refresh Token prüfen
    • Supabase.auth.refreshSession()
      ↓
5️⃣ Neuer Access Token erhalten
      ↓
6️⃣ Tokens sicher speichern
      ↓
7️⃣ Benutzerprofil laden
      ↓
8️⃣ App-State initialisieren ✅
```

</td>
<td width="50%" valign="top">

#### 🚪 Logout
```
1️⃣ Benutzer öffnet Profil
      ↓
2️⃣ Klick auf "Abmelden" Button
      ↓
3️⃣ Bestätigungs-Dialog (optional):
    "Wirklich abmelden?"
      ↓
4️⃣ AuthService:
    • Supabase.auth.signOut()
      ↓
5️⃣ Session löschen:
    • Access Token löschen
    • Refresh Token löschen
    • Secure Storage leeren
      ↓
6️⃣ App-State zurücksetzen:
    • User = null
    • Profile = null
      ↓
7️⃣ Navigation zum Login-Screen
      ↓
8️⃣ Toast: "Erfolgreich abgemeldet" ✅
```

</td>
</tr>
</table>
---

### ⚡ Technische Herausforderungen & Lösungen

<table>
<tr>
<td valign="top">

#### 🌍 API-Übersetzung
**❌ Problem:** USDA API liefert nur englische Lebensmittel-Namen, App ist auf Deutsch

**✅ Lösung:** Automatische DE↔EN Übersetzung mit LibreTranslate + MyMemory Fallback und lokalem Cache

</td>
</tr>
<tr>
<td valign="top">

#### ⚡ Nährwert-Performance
**❌ Problem:** 25+ sequenzielle API-Calls verursachten Ladezeiten von 30+ Sekunden

**✅ Lösung:** Parallele Verarbeitung mit `Future.wait()` reduzierte Ladezeit auf 3-5 Sekunden

</td>
</tr>
<tr>
<td valign="top">

#### 💾 State Management
**❌ Problem:** Tracking ungespeicherter Änderungen bei Rezept-Bearbeitung

**✅ Lösung:** Dirty-Flag System mit `PopScope` (Flutter 3.12+) für Bestätigungs-Dialoge

</td>
</tr>
<tr>
<td valign="top">

#### 📱 UI/UX Optimierung
**❌ Problem:** Layout-Probleme auf kleinen Geräten (z.B. iPhone SE)

**✅ Lösung:** Responsive Design mit `MediaQuery` und `LayoutBuilder` für adaptive Layouts

</td>
</tr>
</table>

---

<div align="center">

## ✅ Anforderungen & Umsetzung

</div>

### 🎯 Obligatorische Anforderungen

<table>
<tr>
<th width="5%" align="center">Status</th>
<th width="40%">Anforderung</th>
<th width="55%">Beschreibung</th>
</tr>

<tr>
<td align="center">✅</td>
<td><strong>CRUD von Rezepten</strong></td>
<td>Erstellen, Lesen, Bearbeiten und Löschen von Rezepten mit Bildern, Zutaten, Anweisungen und Metadaten</td>
</tr>

<tr>
<td align="center">✅</td>
<td><strong>Verschlagwortung (Tagging)</strong></td>
<td>Kategorisierung durch Tags wie Vegan, Glutenfrei, Vegetarisch für Organisation und Suche</td>
</tr>

<tr>
<td align="center">✅</td>
<td><strong>Nährwertansicht</strong></td>
<td>Automatische Berechnung mit USDA API, Anzeige pro Rezept und pro Portion</td>
</tr>

<tr>
<td align="center">✅</td>
<td><strong>Rezeptsuche</strong></td>
<td>Suche nach Namen, Zutaten und Tags mit Filterung nach Ernährungspräferenzen</td>
</tr>

<tr>
<td align="center">✅</td>
<td><strong>Bewertungssystem</strong></td>
<td>5-Sterne-Bewertung mit optionalen Kommentaren, Durchschnitt pro Rezept</td>
</tr>

<tr>
<td align="center">✅</td>
<td><strong>Teilen-Funktion</strong></td>
<td>Teilen via Email, WhatsApp, Telegram und andere Messenger</td>
</tr>

<tr>
<td align="center">✅</td>
<td><strong>Benutzer-Authentifizierung</strong></td>
<td>Sichere Registrierung und Anmeldung mit Email/Passwort</td>
</tr>

</table>

---


> **🎉 Alle definierten Anforderungen wurden erfolgreich umgesetzt!**  
> Es gibt keine nicht-umgesetzten Anforderungen.

---

### 🚀 Mögliche zukünftige Erweiterungen

<table>
<tr>
<td width="50%" valign="top">

#### 👥 Erweiterte Social Features
- Follower-System für Benutzer
- Rezept-Collections (Sammlungen)
- Personalisierte User Feeds

#### 🤖 KI-Integration
- Intelligente Rezept-Empfehlungen basierend auf Vorlieben und Verhalten
- Automatische Zutatenerkennung per Foto
- Generierung von Rezepten aus vorhandenen Zutaten

#### 📵 Offline-Modus
- Lokale Datenspeicherung mit SQLite
- Automatische Synchronisation bei Internetverbindung
- Offline-Zugriff auf gespeicherte Rezepte

</td>
<td width="50%" valign="top">

#### 📊 Erweiterte Analysen
- Nährwert-Tracking über Zeit
- Ernährungsstatistiken und Visualisierungen
- Zielerreichungs-Dashboard

#### 🌍 Multi-Language Support
- Vollständige Internationalisierung (i18n)
- Automatische Übersetzung aller App-Inhalte
- Mehrsprachige Rezepte

#### 🏠 Smart Device Integration
- Anbindung an Smart Kitchen Appliances
- Sprachsteuerung (Alexa, Google Assistant)
- Smart Home Integration

</td>
</tr>
</table>

---

## 🎓 Fazit

### Projekterfolge

RecipeShare demonstriert die Entwicklung einer vollständigen Cross-Platform Mobile App mit modernem Tech-Stack:

✅ **Vollständige Anforderungserfüllung**: Alle obligatorischen und optionalen Anforderungen wurden implementiert  
✅ **Professionelles Design**: Moderne UI/UX mit Material Design 3 und durchdachten Workflows  
✅ **Robuste Backend-Integration**: Zuverlässige Anbindung an Supabase mit PostgreSQL  
✅ **Innovative API-Integration**: Intelligente Kombination von USDA, Übersetzungs-APIs und Caching  
✅ **Performance-Optimierung**: Parallele Verarbeitung reduzierte API-Ladezeiten um 85%  
✅ **Skalierbare Architektur**: Klare Trennung von Präsentations-, Business- und Data-Layer

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

*RecipeShare - Kochrezepte verwalten, entdecken und teilen. Einfach. Lecker. Gemeinsam.* 🍳✨