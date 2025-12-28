# 🔪 kochrezepte_app (Recipe App)

A Flutter project for managing and sharing cooking recipes, featuring modular architecture and a complete rating system.

## 🚀 Getting Started

This project is a starting point for a Flutter application focused on clean code, reusability, and integration with a Supabase backend.

### Prerequisites

- **Flutter SDK**: Ensure Flutter is installed and configured correctly.
- **Supabase Project**: You need a running Supabase instance.
- **Authentication**: The application uses Supabase Auth (email/password) and requires a logged-in user to submit ratings.

## 🛠️ Configuration

Before running the application, you must configure your Supabase URL and Anon Key.

1. Locate the configuration file (e.g., `lib/supabase/supabase_client.dart` or similar).
2. Set your credentials:

```dart
// Example: lib/supabase/supabase_client.dart
final supabaseUrl = 'YOUR_SUPABASE_URL';
final supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

## 📦 Database Schema Requirements

The application relies on specific tables and columns, particularly for the new rating system. Ensure your Supabase schema includes the following:

| Table Name | Purpose | Required Columns |
|------------|---------|------------------|
| **recipes** | Base recipe data and aggregated metrics | `id` (PK), `title`, `duration_minutes`, `servings`, `average_rating` (float8), `total_ratings` (int4) |
| **ratings** | Stores individual user ratings | `recipe_id` (FK to recipes.id), `user_id` (FK to auth.users), `score` (int4, 1-5), Constraints (UNIQUE on user_id, recipe_id) |
| **nutrition** | One-to-one relation for nutrition facts | `recipe_id` (PK, FK to recipes.id), `calories`, `protein_g`, etc. |
| **recipe_ingredients** | Many-to-many relation | `recipe_id`, `ingredient_id`, `quantity`, `unit` |

## 🏗️ Project Structure and Modularization

The project is structured to maximize reusability and maintainability, separating UI components, Models, and Service logic.

### 1. `lib/models/`
Contains the data models, including the core Recipe class.

- **`recipe.dart`**: Updated to include `averageRating` and `totalRatings` fields for the rating system.

### 2. `lib/services/`
Handles all interaction with the Supabase backend.

- **`database_service.dart`**: Updated with two new methods:
  - `rateRecipe(recipeId, score)`: Handles upserting the user's score and recalculating the recipe's aggregate stats.
  - `fetchUserRating(recipeId)`: Retrieves the current user's rating for a specific recipe.

### 3. `lib/widgets/` (The Core of Reusability)
Dedicated folder for reusable UI components.

- **`recipe_card.dart`**: The card component used on the HomePage.
- **`common_widgets.dart`**: Small, generic widgets like `DifficultyBadge` and `InfoChip`.
- **`recipe_detail_items.dart`**: Widgets specific to the detail page (e.g., `IngredientItem`, `StepItem`, `NutritionInfoItem`).
- **`rating_widget.dart`**: **NEW!** The standalone stateful widget that encapsulates all rating logic and UI (stars, prompts, submission).

### 4. `lib/pages/`
The main screens of the application.

- **`home_page.dart`**: Uses `RecipeCard` to display the main list of recipes.
- **`recipe/recipe_detail_page.dart`**: Integrates `RecipeRatingWidget` and the other detail item widgets.
- **`recipe/recipe_form_page.dart`**: (Awaiting further modularization of its dialogues).

## ⭐ Key Feature: Bewertungssystem (Rating System)

The rating system is fully modularized in `lib/widgets/rating_widget.dart`.

### Logic
It tracks the recipe's average rating, the total number of votes, and the specific rating given by the currently logged-in user.

### Interaction
- If the user has not rated, it prompts them to click the stars.
- Once a star is clicked, the "Absenden" (Submit) button appears.
- If the user has rated, it displays their score and the overall average.

### Features
- **Real-time updates**: Ratings are immediately reflected in the UI after submission.
- **User-specific display**: Shows the current user's rating alongside the global average.
- **Error handling**: Gracefully handles authentication and database errors.

## 🎯 Running the Application

1. Clone the repository:
```bash
git clone <your-repo-url>
cd kochrezepte_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Supabase credentials (see Configuration section above).

4. Run the app:
```bash
flutter run
```

## 📱 Features

- ✅ Recipe browsing with cards
- ✅ Detailed recipe view with ingredients, steps, and nutrition
- ✅ User authentication via Supabase
- ✅ Rating system (1-5 stars)
- ✅ Average rating display
- ✅ Modular and reusable widget architecture
- 🚧 Recipe creation and editing (in progress)

## 🤝 Contributing

Contributions are welcome! Please ensure your code follows the modular structure and includes appropriate documentation.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Built with Flutter 💙 and Supabase 🚀**