# Category System

## Architecture Summary
- Source of truth: `assets/data/categories/categories_flat.json`.
- Domain:
  - `CategoryNode` parses localized category nodes (`kk/ru/en`, aliases, keywords, path).
  - `CategoryRepository` loads once from assets, validates graph integrity, builds indices, and caches hot lookups.
- Indices:
  - `byId`
  - `childrenByParent`
  - `leafByRoot`
  - token + prefix search index for multilingual leaf lookup.
- UI:
  - `CategoryPicker` (leaf-only):
    - `singleLeaf` for client order creation
    - `multiLeaf` for worker primary/canDo selection with limits
  - `CategoryNodeFilterPicker` for filter flows that allow selecting root/sub/leaf nodes.

## Business Rules
- Order creation stores only leaf `categoryId`.
- Worker profile category limits:
  - `primaryCategoryIds`: max 3
  - `canDoCategoryIds`: max 20
- Worker can apply to any order; categories affect ranking and badges only.
- UI shows localized category names and breadcrumbs (`kk/ru/en` locale-aware).
- Duplicates across `primaryCategoryIds` and `canDoCategoryIds` are prevented.

## Integration Points
- Client create order:
  - `lib/features/client/request/screens/request_create_screen.dart`
  - writes `categoryId`, `categoryPathIds`, `categoryRootId`, `categoryName`.
- Order domain/service:
  - `lib/features/marketplace/models/order_model.dart`
  - `lib/features/marketplace/services/order_service.dart`
- Worker registration:
  - `lib/features/worker/registration/screens/worker_registration_steps.dart`
  - `lib/features/worker/registration/controller/worker_register_controller.dart`
  - `lib/features/worker/registration/models/worker_register_model.dart`
- Worker feed matching and badges:
  - `lib/features/worker/home/worker_home_screen.dart`
- Worker profile category management:
  - `lib/features/worker/profile/screens/worker_profile_screen.dart`
  - `lib/features/worker/profile/models/worker_profile_data.dart`
- Client worker discovery filtering/ranking:
  - `lib/features/client/home/screens/client_home_screen.dart`
  - `lib/features/client/home/widgets/worker_mini_card.dart`
- Firestore create guard:
  - `firestore.rules` (`validOrderCategoryOnCreate`).

## Extension Notes
- Add/modify categories only in `categories_flat.json`.
- Keep `pathIds` and `isLeaf` consistent with hierarchy to pass validation.
- Popular search defaults are configured in `kPopularLeafCategoryIds`.
- If new locales are added, extend `CategoryLocalizedText`/`CategoryLocalizedList` and locale resolver.
