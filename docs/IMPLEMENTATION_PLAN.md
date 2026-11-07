# План реализации

> Методология: **одна функция — один этап — тесты — коммит**.
> Каждый этап проходит один и тот же цикл (см. раздел 1). Этап считается закрытым, когда выполнены все пункты его Definition of Done и PR влит в `main`.
> Связанные документы: [PROJECT_SPEC.md](PROJECT_SPEC.md) · [USER_STORIES.md](USER_STORIES.md) · [ERD.md](ERD.md) · [WIREFRAMES.md](WIREFRAMES.md) · [CLAUDE.md](CLAUDE.md)

## 1. Рабочий цикл этапа

```
1. git switch main && git pull                 # актуальный main
2. git switch -c feature/<stage-name>          # новая ветка этапа
3. Код: миграции → модели → маршруты → контроллеры → представления
4. Тесты: модели → контроллеры → system
5. bin/ci                                      # rubocop, аудиты, brakeman, тесты, seeds, system
6. Отчёт ассистента → разрешение на коммит → git commit (1–3 логичных коммита)
7. git push -u origin feature/<stage-name> → Pull Request → ревью → merge в main (Енин Андрей)
```

**Соглашение о коммитах (Conventional Commits):**
`feat:` новая функциональность · `fix:` исправление · `test:` тесты · `refactor:` рефакторинг · `style:` вёрстка и стили · `chore:` настройка и зависимости · `ci:` CI · `docs:` документация.
Сообщения пишутся на английском в повелительном наклонении: `feat: add variant size selection on product page`.

### 1.1. Демо-данные растут вместе с магазином
Сайт должен «оживать» по ходу разработки, а не в конце. Поэтому каждый этап, который добавляет модель, сразу дополняет демо-данные:

| Этап | Файл | Что появляется |
|---|---|---|
| 4 | `db/seeds/users.rb` | `admin@example.com` и `customer@example.com` (пароль `password123`) — с этапа 5 можно работать в админке |
| 5 | `db/seeds/categories.rb` | разделы «Мужское», «Женское», «Аксессуары» и их подкатегории |
| 6 | `db/seeds/products.rb` + `db/seeds/catalog.yml` | 30–40 товаров с описанием, ценой и изображением-заглушкой |
| 7 | `db/seeds/variants.rb` (данные в том же `catalog.yml`) | размеры, цвета и остатки, включая нулевые; ONE SIZE у аксессуаров |
| 20 | `db/seeds/orders.rb` и др. | заказы в разных статусах, избранное, подписчики |

Правила:
- `db/seeds.rb` только подключает файлы из `db/seeds/` по порядку.
- Все seeds **идемпотентны** (`find_or_create_by!` по уникальному ключу: email, slug, sku), поэтому повторный `bin/rails db:seed` ничего не дублирует.
- Данные каталога (названия, цены, цвета, размеры) хранятся в `db/seeds/catalog.yml`. Их удобно дополнять без правки Ruby-кода.
- Изображения — однотонные PNG цветов палитры из `db/seeds/images/`. Никаких фото, логотипов и текстов референса.
- Шаг `Tests: Seeds` в `bin/ci` (`db:seed:replant` в test-окружении) проверяет seeds на каждом этапе.
- После этапа 8 команда `bin/rails db:seed` открывает живой каталог с реальными куртками и брюками.

## 2. Сводка этапов и прогресс

Статусы: ✅ готово (в `main`) · 🔄 на ревью (PR открыт) · ☐ не начат.

| # | Этап | Ветка | User Stories | Ответственный | Статус |
|---|---|---|---|---|---|
| 0 | Подготовка окружения | — | — | Андрей | ✅ |
| 1 | Создание приложения и репозитория | `main` | — | Андрей | ✅ |
| 2 | Layout, главная, I18n, исправление CI | `feature/layout-and-i18n` | US-03 (каркас) | Андрей, Рамазан | 🔄 |
| 3 | Аутентификация и регистрация | `feature/authentication` | US-01, US-02 | Андрей | 🔄 |
| 4 | Роли и доступ к админке | `feature/roles` | доступ к US-16…20 | | ☐ |
| 5 | Категории: разделы и подкатегории + админ CRUD | `feature/categories` | US-16 | | ☐ |
| 6 | Товары + изображение + админ CRUD | `feature/products-admin` | US-17 | | ☐ |
| 7 | Варианты (размер, цвет, остаток) + админка | `feature/variants` | US-18 | | ☐ |
| 8 | Каталог по разделам, главная, Pagy | `feature/catalog` | US-03, US-04 | | ☐ |
| 9 | Поиск, фильтры (размер, цвет, цена), сортировка | `feature/search-and-filters` | US-05, US-06 | | ☐ |
| 10 | Страница товара и выбор размера | `feature/product-page` | US-07, US-08 | | ☐ |
| 11 | Избранное | `feature/favorites` | US-14 | | ☐ |
| 12 | Корзина: модели и добавление варианта | `feature/cart` | US-09 | | ☐ |
| 13 | Корзина: страница, Turbo Streams, доставка | `feature/cart-page` | US-10, US-11 | | ☐ |
| 14 | Заказы: модели, транзакция, доставка | `feature/order-models` | US-11, US-12 | | ☐ |
| 15 | Оформление заказа (UI) | `feature/checkout` | US-12 | | ☐ |
| 16 | Личный кабинет | `feature/account-orders` | US-13 | | ☐ |
| 17 | Админ: заказы и статусы | `feature/admin-orders` | US-19 | | ☐ |
| 18 | Подписка на рассылку | `feature/newsletter` | US-15 | | ☐ |
| 19 | Админ: дашборд | `feature/admin-dashboard` | US-20 | | ☐ |
| 20 | Seeds: заказы, избранное, подписчики | `feature/seeds` | — | | ☐ |
| 21 | Полировка UI по дизайн-макету | `feature/ui-polish` | все | | ☐ |
| 22 | Финальная проверка и сдача | `release/v1.0` | все | | ☐ |

---

## Этап 0. Подготовка окружения ✅
Ruby 3.4.1, Rails 8.1.4.1, PostgreSQL 18 (роль `andre_ny7wlah` с правом создавать БД), libpq-dev, Google Chrome 157 для system-тестов. Node.js не нужен.

## Этап 1. Создание приложения и репозитория ✅
`rails _8.1.4.1_ new . --name=topshop --database=postgresql --css=tailwind --skip-kamal`; `config.time_zone = "Moscow"`; `test/application_system_test_case.rb` (headless Chrome); шаг system-тестов в `config/ci.rb`; репозиторий `github.com/FASTer92-maker/topshop`.
Коммиты: `docs: add project documentation`, `chore: generate Rails 8.1 application with PostgreSQL and Tailwind`.

## Этап 2. Layout, главная, I18n 🔄
**Сделано:**
- Дизайн-токены TopShop в `app/assets/tailwind/application.css` (`ink`, `muted`, `surface`, `line`, `accent`…), шрифты Oswald и Inter.
- Layout: чёрная промо-полоса, закреплённая шапка, flash с закрытием (Stimulus `dismiss`), чёрный футер.
- Главная-заглушка, партиалы `shared/_empty_state` и `shared/_form_errors`.
- Локаль `ru` без гема `rails-i18n`: множественные формы, ошибки, даты, рубли, транслитерация для slug. Тексты интерфейса в `views.ru.yml`. Отсутствующий перевод вызывает ошибку в dev и test.
- **Исправление CI:** добавлен начальный `db/schema.rb` (без него `db:test:prepare` на GitHub падал), образ `postgres:18` зафиксирован в `.github/workflows/ci.yml`.

**Тесты:** `HomeControllerTest`, `RussianLocaleTest`, system `LayoutTest` (sticky-шапка, нет горизонтального скролла на 390 px).

---

## Этап 3. Аутентификация и регистрация
**Цель:** US-01, US-02.

**Задачи:**
- [ ] `bin/rails generate authentication`, затем `bin/rails db:migrate`.
- [ ] Миграция: `first_name`, `last_name` (`null: false`) в `users`. Валидации `User` по [ERD §2.1](ERD.md#21-users).
- [ ] `RegistrationsController` (`new`, `create`), `resource :registration, only: %i[new create]`, `allow_unauthenticated_access`, rate limit. В strong params нет `role`.
- [ ] Публичные контроллеры (Home, затем каталог) открыть через `allow_unauthenticated_access`.
- [ ] Формы входа, регистрации и сброса пароля в стиле макета, тексты в `ru.yml`.
- [ ] Шапка: «Войти» → ссылка; для авторизованного «Аккаунт» (меню: Мои заказы, Выйти).

**Тесты:** `UserTest`; `RegistrationsControllerTest` (успех, 422, `role=admin` игнорируется); `SessionsControllerTest`; fixtures `users.yml`; helper входа (`SessionTestHelper` генератора или свой `sign_in_as`); system `RegistrationTest`, `SignInTest`.

**Коммиты:** `feat: generate Rails authentication` · `feat: add user registration with first and last name` · `test: cover registration and sign in`

## Этап 4. Роли и разграничение доступа
**Цель:** серверная защита админки.

**Задачи:**
- [ ] Миграция `role integer, null: false, default: 0` + индекс + check constraint; `enum :role`.
- [ ] `Admin::BaseController` (`before_action :require_admin`, `layout "admin"`), `namespace :admin { root "dashboard#index" }`, заглушка дашборда, `layouts/admin.html.erb`.
- [ ] Пункт «Админ-панель» в меню только для admin.

- [ ] **Демо-данные:** `db/seeds.rb` подключает `db/seeds/*.rb`; `db/seeds/users.rb` — admin и customer (см. раздел 1.1).

**Тесты:** `UserTest` (роль по умолчанию); `Admin::DashboardControllerTest`: гость → вход, customer → главная с «Доступ запрещён», admin → 200.

**Коммиты:** `feat: add user roles with customer default` · `feat: add admin namespace with server-side access control`

## Этап 5. Категории: разделы и подкатегории
**Цель:** US-16. Двухуровневое дерево категорий.

**Задачи:**
- [ ] Миграция `categories`: `parent_id` (FK на `categories`, nullable), `name`, `slug`, `description`, `position`. Уникальный индекс `(parent_id, lower(name))` с `nulls_not_distinct: true`, уникальный `slug`, check `parent_id <> id`. См. [ERD §2.3](ERD.md#23-categories--двухуровневое-дерево).
- [ ] Модель: `parent` / `subcategories`, ограничение глубины 2, генерация slug с префиксом раздела, scopes `sections` и `ordered`, `self_and_subcategory_ids`, `full_name`.
- [ ] `Admin::CategoriesController` (CRUD), дерево в списке, select родителя только из разделов.
- [ ] Fixtures: разделы `men`, `women`, `accessories`; подкатегории `men_jackets`, `women_jackets`, `accessories_bags`.
- [ ] **Демо-данные:** `db/seeds/categories.rb`. Мужское: Куртки, Рубашки, Брюки, Свитшоты, Футболки. Женское: Куртки, Рубашки, Брюки, Юбки, Свитшоты. Аксессуары: Сумки, Головные уборы, Ремни.

**Тесты:** `CategoryTest`:
- «Куртки» можно создать и в «Мужском», и в «Женском», а второй раздел «Мужское» — нельзя;
- подкатегорию нельзя сделать родителем;
- slug `muzhskoe-kurtki`;
- раздел с подкатегориями не удаляется;
- `self_and_subcategory_ids`.

Плюс `Admin::CategoriesControllerTest` и system `AdminCategoriesTest`.

**Коммиты:** `feat: add nested Category model with sections and subcategories` · `feat: add admin categories CRUD` · `test: cover category tree`

## Этап 6. Товары, изображение и их админ-CRUD
**Цель:** US-17 (без вариантов).

**Задачи:**
- [ ] `bin/rails active_storage:install`.
- [ ] Миграция `products`: `category_id`, `name`, `slug`, `description`, `price decimal(10,2)`, `active`. **Без `stock` и `sku`.** Индексы и check `price >= 0` по [ERD §2.4](ERD.md#24-products--модель-одежды).
- [ ] Модель: связи, валидация «категория — подкатегория», `has_one_attached :image` + валидатор типа и размера, slug, scope `active`.
- [ ] `Admin::ProductsController`: CRUD, select подкатегорий с группами по разделам (`grouped_collection_select`), поиск по названию, «Скрыть» = снять «Активен».
- [ ] Fixtures `products.yml`, тестовое изображение `test/fixtures/files/product.png`.
- [ ] **Демо-данные:** `db/seeds/catalog.yml` (30–40 товаров: название, подкатегория, цена, описание с составом и уходом) и `db/seeds/products.rb`, который прикрепляет однотонные PNG из `db/seeds/images/`. Товары видны в админке сразу, на витрине — с этапа 8.

**Тесты:** `ProductTest` (валидации, раздел верхнего уровня не принимается, тип файла, check constraint); `Admin::ProductsControllerTest` (CRUD, `fixture_file_upload`, доступ customer); system `AdminProductsTest`.

**Коммиты:** `chore: install Active Storage` · `feat: add Product model with image attachment` · `feat: add admin products CRUD`

## Этап 7. Варианты: размер, цвет, остаток
**Цель:** US-18. Остатки живут в вариантах.

**Задачи:**
- [ ] `bin/rails g model Variant product:references size:string color:string stock:integer sku:string`, в миграции `null: false`, `default: 0` для `stock`, check `stock >= 0`, уникальные `(product_id, size, color)` и `sku`, индексы `size` и `color`. См. [ERD §2.5](ERD.md#25-variants--размер-и-цвет-товара-новая-таблица).
- [ ] Модель: `SIZES`, нормализация `sku` и `color`, валидации, scopes `in_stock`, `low_stock`, `by_size`; `available?`, `label`.
- [ ] `Product`: `has_many :variants` (в порядке размеров), `has_many :order_items, through: :variants`, `before_destroy :ensure_not_ordered, prepend: true`; методы `in_stock?`, `available_sizes`, `colors`; scope `in_stock`.
- [ ] `Admin::VariantsController` — вложенный ресурс `resources :products { resources :variants, except: %i[index show] }`. Таблица вариантов на `admin/products#show`, создание и изменение через Turbo Stream, подсветка остатка < 3.
- [ ] Поиск товаров в админке дополнительно по артикулу варианта.
- [ ] **Демо-данные:** варианты в `db/seeds/catalog.yml` (1–3 цвета из палитры макета × 3–6 размеров, разные остатки, часть нулевых; ONE SIZE у аксессуаров) и `db/seeds/variants.rb`.

**Тесты:** `VariantTest` (все валидации, уникальность размер + цвет, нормализация, `available?` для скрытого товара, порядок размеров); `ProductTest` (`available_sizes`, `colors`, `in_stock`); `Admin::VariantsControllerTest`; system `AdminVariantsTest`.

**Коммиты:** `feat: add Variant model with size, color and stock` · `feat: manage product variants in admin` · `test: cover variants`

## Этап 8. Каталог по разделам, главная, пагинация
**Цель:** US-03, US-04.

**Задачи:**
- [ ] Гем `pagy` (актуальная стабильная версия), подключить по README **установленной** версии. API между мажорными версиями отличается. Лимит 12, стили Tailwind.
- [ ] Меню разделов в шапке («Все · Мужское · Женское · Аксессуары») из `Category.sections.ordered`.
- [ ] `ProductsController#index` и `CategoriesController#show` (по slug) с общим партиалом сетки внутри `turbo_frame_tag "catalog"`. В разделе выводятся товары подкатегорий и чипы подкатегорий. Счётчик «N товаров». Хлебные крошки.
- [ ] Карточка `products/_product`: фото 3:4, название (Oswald), цвета, цена, «Нет в наличии». Без N+1: `includes(:variants, category: :parent)`, `with_attached_image`.
- [ ] Главная: баннеры «Мужское» и «Женское» со ссылками на разделы, «Новинки» (8 штук, горизонтальная прокрутка).
- [ ] Pagy в админских списках.

**Тесты:** `ProductTest#in_category` (раздел включает подкатегории); `ProductsControllerTest`; `CategoriesControllerTest` (раздел, подкатегория, 404); `HomeControllerTest`; system `CatalogBrowsingTest`.

**Коммиты:** `chore: add pagy gem` · `feat: add catalog by sections and subcategories` · `feat: add home page banners and new arrivals`

## Этап 9. Поиск, фильтры и сортировка
**Цель:** US-05, US-06.

**Задачи:**
- [ ] Scopes `search`, `price_from`, `price_to`, `in_stock`, `with_size`, `with_color`, `sorted_by` и `filter_by(params)` в `Product` (подзапросы по `variants`, без дублей). Контроллер только вызывает `Product.active.filter_by(filter_params)`.
- [ ] Безопасная обработка параметров: `sanitize_sql_like`, `BigDecimal(value, exception: false)`, размер только из `Variant::SIZES`, белый список сортировок.
- [ ] Панель фильтров (GET-форма, `data-turbo-frame="catalog"`, `data-turbo-action="advance"`), автоотправка (Stimulus `auto_submit`), «Сбросить», пустой результат «Ничего не найдено. Измените фильтры.».
- [ ] Поиск в шапке.

**Тесты:** `ProductTest` (каждый scope отдельно и в комбинации; размер не в наличии не находится; нет дублей при нескольких подходящих вариантах; экранирование `%`; некорректные значения игнорируются); `ProductsControllerTest`; system `SearchTest`, `FilterTest`.

**Коммиты:** `feat: add product search and variant filters` · `feat: add catalog filter bar with Turbo Frame` · `test: cover search and filters`

## Этап 10. Страница товара и выбор размера
**Цель:** US-07, US-08.

**Задачи:**
- [ ] `ProductsController#show` по slug, только активные.
- [ ] Выбор цвета и размера: радиокнопки `variant_id`, размеры без остатка `disabled`. Stimulus-контроллер `variant_picker` переключает размеры при смене цвета, показывает «Осталось N шт.», а при отправке без размера выводит «Выберите размер». Единственный вариант выбирается автоматически.
- [ ] Блок «Похожие товары» (та же подкатегория, до 4 штук).
- [ ] Форма «В корзину» ведёт на маршрут этапа 12. До этапа 12 кнопка видна, но неактивна.

**Тесты:** `ProductsControllerTest#show` (200, 404 для скрытого, disabled-размеры в разметке); system `SizeSelectionTest` (без размера → «Выберите размер»; ONE SIZE выбран сам).

**Коммиты:** `feat: add product page with color and size selection`

## Этап 11. Избранное
**Цель:** US-14.

**Задачи:**
- [ ] `bin/rails g model Favorite user:references product:references` + уникальный индекс `(user_id, product_id)`.
- [ ] `User#favorite?`, `#toggle_favorite!`; связи по [ERD §2.6](ERD.md#26-favorites--избранное-новая-таблица).
- [ ] `FavoritesController`: `index`, `create`, `destroy` (вход обязателен). Ответ Turbo Stream заменяет кнопку `dom_id(product, :favorite)` и счётчик ♡ в шапке.
- [ ] Партиал `favorites/_button` на карточке и странице товара. Страница `/favorites`.

**Тесты:** `FavoriteTest`; `UserTest#toggle_favorite!`; `FavoritesControllerTest` (гость → вход, toggle, только свои); system `FavoritesTest`.

**Коммиты:** `feat: add Favorite model` · `feat: toggle favorites with Turbo Streams` · `test: cover favorites`

## Этап 12. Корзина: модели и добавление варианта
**Цель:** US-09.

**Задачи:**
- [ ] `bin/rails g model Cart user:references` (уникальный `user_id`); `bin/rails g model CartItem cart:references variant:references quantity:integer` (default 1, check `> 0`, уникальный `(cart_id, variant_id)`).
- [ ] `User#cart!`, `Cart#add_variant`, `#subtotal`, `#items_count`, `CartItem#subtotal`, валидация остатка варианта по [ERD §2.8–2.9](ERD.md#28-carts).
- [ ] `CartItemsController#create` (вход обязателен): `params.expect(:variant_id, :quantity)`. Без `variant_id` возвращается ошибка «Выберите размер». Ответы: Turbo Stream (счётчик и flash) и redirect на `/cart`.
- [ ] Счётчик «Корзина (N)» в шапке (`id="cart_counter"`), кнопка «В корзину» на странице товара становится активной.

**Тесты:** `CartTest#add_variant` (новый вариант, увеличение количества, другой размер — новая строка, превышение остатка, скрытый товар); `CartItemTest`; `CartItemsControllerTest` (гость → вход, без `variant_id` → ошибка); system `AddToCartTest`.

**Коммиты:** `feat: add Cart and CartItem models referencing variants` · `feat: add variant to cart` · `test: cover cart logic`

## Этап 13. Корзина: страница, Turbo Streams, доставка
**Цель:** US-10, US-11.

**Задачи:**
- [ ] Модуль тарифов `Delivery` (`app/models/delivery.rb`): `FREE_FROM = 10_000`, `PRICE = 400`, `price_for`, `amount_to_free`. См. [ERD §2.10](ERD.md#210-orders). На этапе 14 им же пользуется `Order`.
- [ ] `Cart#delivery_price`, `#total`, `#amount_to_free_delivery`, `#checkout_ready?`, `#unavailable_items`.
- [ ] `resource :cart, only: :show`, `CartItemsController#update/destroy` через `Current.user.cart!.cart_items.find`.
- [ ] Страница корзины: строки с фото, названием, «M · Чёрный», «−» / «+», «Удалить». Блок итога: товары, доставка, итого, подсказка «До бесплатной доставки: N ₽». Turbo Stream-шаблоны обновляют строку, итог и счётчик. «Корзина пуста.»

**Тесты:** `DeliveryTest` (9 999 → 400; 10 000 → 0; `amount_to_free`); `CartTest` (доставка, итог, подсказка); `CartItemsControllerTest` (update, destroy, чужой item → 404, количество 0 → удаление); system `CartManagementTest`.

**Коммиты:** `feat: add Delivery pricing module` · `feat: add cart page with Turbo Stream updates` · `test: cover cart management and delivery`

## Этап 14. Заказы: модели, транзакция, доставка
**Цель:** бизнес-логика US-11, US-12 и отмены (US-19).

**Задачи:**
- [ ] `Order`: `user`, `number`, `status` (0..5, включая `assembled`), `subtotal`, `delivery_price`, `total`, данные доставки. Check constraints, в том числе `total = subtotal + delivery_price`. См. [ERD §2.10](ERD.md#210-orders).
- [ ] `OrderItem`: `order`, `variant`, снимки `product_name`, `size`, `color`, `unit_price`, `quantity`. См. [ERD §2.11](ERD.md#211-order_items).
- [ ] `Order.place_from_cart!` по [ERD §4](ERD.md#4-транзакция-оформления-заказа-orderplace_from_cart): блокировка вариантов по `id`, уменьшение `variants.stock`, снимки, доставка.
- [ ] `TRANSITIONS`, `can_transition_to?`, `available_transitions`, `transition_to!`, `cancel!` (возврат остатков вариантов), scopes `recent`, `not_cancelled`, `revenue`.
- [ ] Ошибки `Order::EmptyCartError` и `Order::InsufficientStockError` (с вариантом в сообщении).

**Тесты (главный блок проекта):**
- `OrderTest.place_from_cart!`:
  - успех: позиции со снимками размера, цвета и цены, остатки вариантов уменьшены, корзина пуста;
  - `subtotal`, `delivery_price` и `total` верны для сумм ниже и выше порога;
  - нехватка остатка → исключение, ничего не изменилось;
  - пустая корзина → `EmptyCartError`;
  - изменение цены или цвета после заказа не меняет снимок.
- `OrderTest`: все разрешённые и запрещённые переходы, `cancel!` из статуса `assembled` возвращает остатки, повторная отмена запрещена.
- `OrderItemTest`.

**Коммиты:** `feat: add Order and OrderItem models with snapshots` · `feat: place order from cart in a transaction with variant locking` · `feat: add order status transitions and cancellation` · `test: cover order placement and transitions`

## Этап 15. Оформление заказа (UI)
**Цель:** US-12.

**Задачи:**
- [ ] `resources :orders, only: %i[index show new create]`.
- [ ] `new`: если корзина пуста или не готова к оформлению, редирект в корзину. ФИО заполняется из профиля.
- [ ] Форма внутри `turbo_frame_tag "checkout"`, ошибки с `422`. Состав заказа с размерами и доставкой.
- [ ] `create`: `Order.place_from_cart!`, обработка `InsufficientStockError` (редирект в корзину) и `RecordInvalid` (422). Экран «Заказ принят» на `show` с пометкой об имитации оплаты.
- [ ] `data-turbo-submits-with` против двойной отправки.

**Тесты:** `OrdersControllerTest` (пустая корзина, успех, 422, нехватка, чужой заказ → 404); system `CheckoutTest` (выбор размера → корзина → оформление → «Заказ принят», остаток варианта уменьшился).

**Коммиты:** `feat: add checkout form and order confirmation` · `test: add end-to-end checkout system test`

## Этап 16. Личный кабинет
**Цель:** US-13.

**Задачи:** `OrdersController#index` (`Current.user.orders.recent` + Pagy); карточка заказа со шкалой статусов; `OrdersHelper#status_badge` (цвета по [ERD §3](ERD.md#3-статусы-заказа-и-переходы)); переводы статусов; меню «Аккаунт → Мои заказы / Избранное». *(Could)* Отмена своего заказа в статусе «Новый».

**Тесты:** `OrdersControllerTest#index` (только свои); helper test `status_badge`; system `OrderHistoryTest`.

**Коммиты:** `feat: add customer order history`

## Этап 17. Админ: заказы и статусы
**Цель:** US-19.

**Задачи:** `Admin::OrdersController` (index с вкладками по 6 статусам и Pagy, show, update). `update` → `order.transition_to!` → Turbo Stream (бейдж, кнопки, flash). Позиции со снимками размера и цвета.

**Тесты:** `Admin::OrdersControllerTest` (фильтр, допустимый и недопустимый переход, отмена возвращает остатки вариантов, customer → запрет); system `AdminOrdersTest` (новый → оплачен → собран без перезагрузки).

**Коммиты:** `feat: add admin orders list with status filter` · `feat: change order status via Turbo Streams`

## Этап 18. Подписка на рассылку
**Цель:** US-15.

**Задачи:**
- [ ] `bin/rails g model Subscriber email:string:uniq`, `null: false`; нормализация, валидации, `Subscriber.subscribe`.
- [ ] `SubscribersController#create` (`allow_unauthenticated_access`, rate limit), `resources :subscribers, only: :create`.
- [ ] Блок «Новости и акции» над футером в `turbo_frame_tag "newsletter"`: при успехе «Спасибо! Подписка оформлена.», при ошибке — сообщение внутри блока.
- [ ] Число подписчиков на дашборде (этап 19).

**Тесты:** `SubscriberTest`; `SubscribersControllerTest` (успех, повтор не создаёт дубль и даёт тот же ответ, 422 при неверном email); system `NewsletterTest`.

**Коммиты:** `feat: add newsletter subscription`

## Этап 19. Админ: дашборд *(Could)*
**Цель:** US-20. Карточки (`Order.group(:status).count`, `Order.revenue`, товары, подписчики), список `Variant.low_stock` с товаром, последние 5 заказов.

**Тесты:** `Admin::DashboardControllerTest`, `VariantTest#low_stock`, `OrderTest#revenue`.

**Коммиты:** `feat: add admin dashboard with store statistics`

## Этап 20. Seeds: заказы, избранное, подписчики (финальное демо)
**Цель:** дополнить демо-данные, которые росли с этапа 4 (см. раздел 1.1), до полного сценария сдачи.

**Задачи:**
- [ ] `db/seeds/orders.rb`: 3–5 заказов демо-покупателя в разных статусах через `Order.place_from_cart!` (остатки уменьшаются честно).
- [ ] Избранное демо-покупателя (4–6 товаров), 2–3 подписчика.
- [ ] Проверить, что весь набор seeds идемпотентен и укладывается в пару секунд.

**Тесты:** `bin/rails db:reset` дважды подряд без ошибок; шаг `Tests: Seeds` в `bin/ci`.

**Коммиты:** `chore: add demo orders, favorites and subscribers to seeds`

## Этап 21. Полировка UI по дизайн-макету
**Цель:** привести все экраны к дизайн-макету TopShop (PDF): шкала шрифтов, отступы 16–40 px, скругления 4/6/8 px, границы `#DAD8D3` без теней.

**Задачи:** проверка на ширинах 390, 768 и 1440 px; страницы 404, 422 и 500 в стиле магазина; фокус-состояния и `alt` у изображений; поиск N+1 в логах; все строки интерфейса берутся из `ru.yml`. *(Could)* Баннер cookie («Принять»).

**Коммиты:** `style: polish layout to match design mockups` · `style: add custom error pages`

## Этап 22. Финальная проверка и сдача
**Задачи:**
- [ ] `bin/ci` полностью зелёный, CI на GitHub зелёный.
- [ ] Пройти вручную все User Stories с приоритетом Must и Should по критериям приемки.
- [ ] `README.md`: описание, стек, установка (`bin/setup`, `bin/rails db:seed`, `bin/dev`), демо-аккаунты, тесты, ссылки на `docs/`.
- [ ] Сценарий демо (7–8 минут):
  1. гость: главная → «Мужское» → «Куртки» → фильтр по размеру M → товар;
  2. регистрация → ♡ в избранное → выбрать размер → корзина (подсказка про бесплатную доставку) → оформление → «Заказ принят» → заказ в ЛК;
  3. подписка на рассылку из футера;
  4. админ: новый заказ → оплачен → собран → отправлен; отмена другого заказа с возвратом остатков;
  5. админ: товар → варианты → изменение остатка;
  6. попытка customer открыть `/admin` → отказ;
  7. тесты и история Git.
- [ ] Тег `v1.0.0`, обновить статусы в таблице раздела 2.

**Коммиты:** `docs: add README with setup and demo instructions` · `chore: release v1.0.0`

---

## 3. Карта тестов

| Слой | Расположение | Что проверяем |
|---|---|---|
| Модели (Unit) | `test/models/*_test.rb` | валидации; дерево категорий; варианты и остатки; scopes каталога; `Cart#add_variant`; доставка; `Order.place_from_cart!`; переходы статусов; `cancel!`; избранное; подписка |
| Локаль | `test/i18n/*_test.rb` | рубли, множественные формы, транслитерация, даты |
| Хелперы | `test/helpers/*_test.rb` | бейдж статуса, форматирование |
| Контроллеры (Integration) | `test/controllers/**/*_test.rb` | доступ по ролям, редиректы, коды ответов, Turbo Stream/Frame-ответы, скоупинг чужих данных |
| System (Feature) | `test/system/*_test.rb` | регистрация и вход, каталог и фильтры, выбор размера, избранное, корзина и доставка, оформление, ЛК, подписка, админ: категории, товары, варианты, заказы |

Минимальная цель — каждая User Story закрыта хотя бы одним system- или integration-тестом, а вся бизнес-логика в моделях покрыта unit-тестами.

## 4. Риски и решения

| Риск | Решение |
|---|---|
| Гонка при одновременной покупке последнего размера | `lock!` вариантов в транзакции в порядке `variant_id`, check constraint `variants.stock >= 0` |
| Дубли товаров в выдаче при фильтре по вариантам | фильтры через подзапросы `where(id: Variant....select(:product_id))`, а не JOIN |
| Удаление товара с вариантами из заказов | `before_destroy :ensure_not_ordered, prepend: true` + `restrict_with_error` у вариантов |
| Одинаковые имена подкатегорий в разных разделах | уникальность в рамках `parent_id`, глобально уникальный slug с префиксом раздела |
| Slug из кириллицы | правило транслитерации в `ru.yml` (уже покрыто тестами) |
| CI падает без `db/schema.rb` | начальная схема в репозитории (исправлено на этапе 2) |
| Pagy поменял API между версиями | следовать README установленной версии, версия зафиксирована в `Gemfile.lock` |
| Конфликты миграций в команде | миграции создаёт только ответственный за этап (по схеме — Марат), короткие ветки, частый `git pull` |
| Turbo «съедает» ошибки форм | рендерить ошибки с `status: :unprocessable_content` |
