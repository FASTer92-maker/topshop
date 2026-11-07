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
5. bin/rails test && bin/rails test:system     # всё зелёное
6. bin/rubocop && bin/brakeman                 # без замечаний
7. Отчёт ассистента → разрешение на коммит → git commit (1–3 логичных коммита)
8. git push -u origin feature/<stage-name> → Pull Request → ревью → merge в main
```

**Соглашение о коммитах (Conventional Commits):**
`feat:` новая функциональность · `fix:` исправление · `test:` тесты · `refactor:` рефакторинг · `style:` вёрстка и стили · `chore:` настройка и зависимости · `docs:` документация.
Сообщения пишутся на английском в повелительном наклонении: `feat: add cart item quantity update via Turbo Streams`.

## 2. Сводка этапов и прогресс

| # | Этап | Ветка | User Stories | Ответственный | Статус |
|---|---|---|---|---|---|
| 0 | Подготовка окружения | — | — | | ☐ |
| 1 | Создание приложения и репозитория | `main` (initial) | — | | ☐ |
| 2 | Layout, главная, I18n | `feature/layout-and-i18n` | US-03 | | ☐ |
| 3 | Аутентификация и регистрация | `feature/authentication` | US-01, US-02 | | ☐ |
| 4 | Роли и доступ к админке | `feature/roles` | US-12…14 (доступ) | | ☐ |
| 5 | Категории + админ CRUD | `feature/categories` | US-12 | | ☐ |
| 6 | Товары + изображения + админ CRUD | `feature/products-admin` | US-13 | | ☐ |
| 7 | Каталог, категории, Pagy | `feature/catalog` | US-03, US-04 | | ☐ |
| 8 | Поиск, фильтры, сортировка | `feature/search-and-filters` | US-05, US-06 | | ☐ |
| 9 | Страница товара | `feature/product-page` | US-07 | | ☐ |
| 10 | Корзина: модели и добавление | `feature/cart` | US-08 | | ☐ |
| 11 | Корзина: страница и Turbo Streams | `feature/cart-page` | US-09 | | ☐ |
| 12 | Заказы: модели и транзакция | `feature/order-models` | US-10 | | ☐ |
| 13 | Оформление заказа (UI) | `feature/checkout` | US-10 | | ☐ |
| 14 | Личный кабинет | `feature/account-orders` | US-11 | | ☐ |
| 15 | Админ: заказы и статусы | `feature/admin-orders` | US-14 | | ☐ |
| 16 | Админ: дашборд | `feature/admin-dashboard` | US-15 | | ☐ |
| 17 | Seeds с демо-данными | `feature/seeds` | — | | ☐ |
| 18 | Полировка UI | `feature/ui-polish` | все | | ☐ |
| 19 | Финальная проверка и сдача | `release/v1.0` | все | | ☐ |

---

## Этап 0. Подготовка окружения
**Цель:** на машине каждого участника есть всё, что нужно для запуска и тестов.

**Задачи:**
- [ ] Проверить Ruby: `ruby -v` → 3.4.x (сейчас 3.4.1).
- [ ] Установить Rails 8.1: `gem install rails -v '~> 8.1.0'`, проверить `rails _8.1.X_ -v` (сейчас глобально стоит 7.2.2.1).
- [ ] PostgreSQL: сервис запущен (`sudo service postgresql start` в WSL), у текущего пользователя есть роль с правом создавать БД: `sudo -u postgres createuser -s $USER`.
- [ ] Установить dev-заголовки для гема `pg`: `sudo apt install libpq-dev`.
- [ ] Для system-тестов установить Google Chrome или Chromium в WSL. Chromedriver Selenium Manager подтянет сам.
- [ ] Git: `git config --global user.name / user.email`, доступ к GitHub (SSH-ключ или `gh auth login`).
- [ ] Node.js **не нужен**: importmap и standalone-бинарник Tailwind.

**Definition of Done:** `rails _8.1.X_ -v`, `psql -c 'select 1'` и `google-chrome --version` (или `chromium --version`) выполняются без ошибок.

---

## Этап 1. Создание приложения и репозитория
**Цель:** пустое приложение Rails 8.1 запускается, есть репозиторий на GitHub, CI зелёный.

**Задачи:**
- [ ] В корне проекта, где уже лежит `docs/`, выполнить:
  `rails _8.1.X_ new . --database=postgresql --css=tailwind --skip-kamal`
  (деплой не нужен, поэтому Kamal пропускаем; остальные значения по умолчанию оставляем).
- [ ] `bin/rails db:create`, `bin/dev`, проверить, что http://localhost:3000 открывается.
- [ ] `config.time_zone = "Moscow"`, `config.i18n.default_locale = :ru` (переводы на этапе 2).
- [ ] Проверить наличие `test/application_system_test_case.rb` (headless Chrome). Если его нет, создать.
- [ ] Корневой `CLAUDE.md`, который импортирует `@docs/CLAUDE.md`.
- [ ] `git init`, проверить `.gitignore` (`/config/master.key`, `/storage/*`, `/tmp/*`, `/log/*`).
- [ ] Создать репозиторий на GitHub, включить защиту `main` (обязательный PR и зелёный CI).
- [ ] Проверить сгенерированный `.github/workflows/ci.yml` (rubocop, brakeman, tests) и, если есть, `bin/ci`.

**Тесты:** `bin/rails test` (пустой прогон проходит), `bin/rubocop`, `bin/brakeman`.

**Коммиты:**
- `docs: add project documentation`
- `chore: generate Rails 8.1 application with PostgreSQL and Tailwind`

**DoD:** приложение стартует, CI на GitHub зелёный, `main` защищён.

---

## Этап 2. Layout, главная страница, I18n
**Цель:** у магазина есть единый внешний вид и русская локализация.

**Задачи:**
- [ ] `HomeController#index`, `root "home#index"` (пока заглушка: баннер и «Каталог скоро»).
- [ ] Layout: `_header` (логотип, поиск-заглушка, меню), `_flash`, `_footer` по [WIREFRAMES §1](WIREFRAMES.md#1-общий-layout).
- [ ] `config/locales/ru.yml`: базовые сообщения ActiveRecord (`errors.messages.blank`, `taken`, `too_short`…), форматы дат, `number.currency.format` (`unit: "₽"`, `format: "%n %u"`, `delimiter: " "`, `precision: 0`), `i18n.transliterate.rule` для кириллицы (нужно для slug).
  Гем `rails-i18n` подключаем **только по согласованию** команды, по умолчанию пишем минимальный `ru.yml` вручную.
- [ ] Партиалы `shared/_form_errors`, `shared/_empty_state`.

**Тесты:** `HomeControllerTest` (200, заголовок), тест на `number_to_currency(1990)` → `"1 990 ₽"` (helper test).

**Коммиты:** `feat: add application layout with header, flash and footer` · `feat: add Russian locale and currency format`

**DoD:** главная открывается, вёрстка адаптивная, тексты на русском.

---

## Этап 3. Аутентификация и регистрация
**Цель:** пользователь может зарегистрироваться, войти, выйти и сбросить пароль (US-01, US-02).

**Задачи:**
- [ ] `bin/rails generate authentication`, затем `bin/rails db:migrate`. Генератор создаёт `User`, `Session`, `Current`, concern `Authentication`, `SessionsController`, `PasswordsController` и `PasswordsMailer`.
- [ ] Миграция: `first_name`, `last_name` (`null: false`) в `users`.
- [ ] `RegistrationsController` (`new`, `create`), маршрут `resource :registration, only: %i[new create]`, `allow_unauthenticated_access`, rate limit на `create`.
- [ ] Strong params: `email_address`, `first_name`, `last_name`, `password`, `password_confirmation` (без `role`!).
- [ ] Валидации `User` по [ERD §2.1](ERD.md#21-users).
- [ ] Стилизовать формы входа, регистрации и сброса пароля Tailwind'ом, перевести тексты.
- [ ] Шапка: меню гостя и меню авторизованного пользователя (`authenticated?`, `Current.user`).
- [ ] По умолчанию генератор закрывает все контроллеры. Для публичных страниц (Home, а потом каталог) добавить `allow_unauthenticated_access`.

**Тесты:**
- `UserTest`: валидации, нормализация email, уникальность, длина пароля.
- `RegistrationsControllerTest`: успех → сессия создана; ошибки → 422; `role=admin` игнорируется.
- `SessionsControllerTest`: верные и неверные данные, выход.
- Fixtures `users.yml`: `customer`, `admin` (позже), пароль через `BCrypt::Password.create("password")`.
- Helper входа для тестов: использовать `SessionTestHelper`, если генератор его создал, иначе написать свой `sign_in_as(user)`.
- System `RegistrationTest`, `SignInTest`.

**Коммиты:** `feat: generate Rails authentication` · `feat: add user registration with first and last name` · `test: cover registration and sign in`

**DoD:** все сценарии US-01 и US-02 проходят, тесты зелёные.

---

## Этап 4. Роли и разграничение доступа
**Цель:** есть роли customer и admin, админка закрыта на сервере.

**Задачи:**
- [ ] Миграция: `role integer, null: false, default: 0` + индекс + check constraint.
- [ ] `enum :role, { customer: 0, admin: 1 }, default: :customer` в `User`.
- [ ] `Admin::BaseController < ApplicationController`: `before_action :require_admin`, `layout "admin"`.
  `require_admin` → `redirect_to root_path, alert: t("errors.access_denied") unless Current.user&.admin?`.
- [ ] `namespace :admin { root "dashboard#index" }`, заглушка `Admin::DashboardController`, `layouts/admin.html.erb`.
- [ ] Пункт «Админ-панель» в меню виден только админу.
- [ ] Rake-задача или консольная команда для назначения админа (`User.find_by(email_address:).admin!`), в seeds на этапе 17.

**Тесты:**
- `UserTest`: роль по умолчанию `customer`, `admin?`.
- `Admin::DashboardControllerTest`: гость → редирект на вход; customer → редирект на главную с alert; admin → 200.

**Коммиты:** `feat: add user roles with customer default` · `feat: add admin namespace with server-side access control`

**DoD:** доступ к `/admin` есть только у admin, это подтверждено тестами.

---

## Этап 5. Категории и их админ-CRUD
**Цель:** админ управляет категориями (US-12).

**Задачи:**
- [ ] `bin/rails g model Category name:string slug:string:uniq description:text`, в миграции `null: false` и уникальный индекс `lower(name)`.
- [ ] Модель по [ERD §2.3](ERD.md#23-categories): валидации, генерация slug, `to_param`, `restrict_with_error`.
- [ ] `Admin::CategoriesController` (index, new, create, edit, update, destroy), `resources :categories, except: :show` в namespace admin.
- [ ] Представления по [WIREFRAMES §12](WIREFRAMES.md#12-админ-категории), ошибки формы с `status: :unprocessable_content`.

**Тесты:**
- `CategoryTest`: обязательность и уникальность имени, генерация slug из кириллицы (`"Дом и сад"` → `"dom-i-sad"`), формат slug, запрет удаления с товарами (после этапа 6 дополнить).
- `Admin::CategoriesControllerTest`: CRUD под admin; customer → редирект.
- System `AdminCategoriesTest`: создать, переименовать, удалить.

**Коммиты:** `feat: add Category model with slug generation` · `feat: add admin categories CRUD` · `test: cover admin categories`

---

## Этап 6. Товары, изображения и их админ-CRUD
**Цель:** админ управляет товарами с изображением (US-13).

**Задачи:**
- [ ] `bin/rails active_storage:install` и миграция.
- [ ] `bin/rails g model Product category:references name:string slug:string:uniq sku:string:uniq description:text price:decimal{10,2} stock:integer active:boolean`, в миграции `null: false`, default'ы, индексы и check constraints по [ERD §2.4](ERD.md#24-products).
- [ ] Модель: связи, валидации, `has_one_attached :image`, валидатор типа и размера изображения (собственный, в `app/validators/` или в модели), slug, scope `active`.
- [ ] `Category`: добавить `has_many :products, dependent: :restrict_with_error`.
- [ ] `Admin::ProductsController`: CRUD, поиск по имени и SKU, пагинация пока без Pagy (Pagy на этапе 7, потом подключить и здесь).
- [ ] Удаление: при `restrict_with_error` показать alert. «Скрыть» = снять флажок «Активен».
- [ ] Представления по [WIREFRAMES §11](WIREFRAMES.md#11-админ-товары). Миниатюры через `image_tag product.image` + CSS, без variants.
- [ ] Fixtures `products.yml`, `categories.yml`. Тестовое изображение `test/fixtures/files/product.png`.

**Тесты:**
- `ProductTest`: все валидации, check constraint (`update_column(:stock, -1)` → `ActiveRecord::StatementInvalid`), недопустимый тип файла, scope `active`.
- `Admin::ProductsControllerTest`: CRUD, загрузка файла (`fixture_file_upload`), доступ customer.
- System `AdminProductsTest`: создание товара с изображением.

**Коммиты:** `chore: install Active Storage` · `feat: add Product model with validations and image attachment` · `feat: add admin products CRUD` · `test: cover products model and admin`

---

## Этап 7. Каталог, страницы категорий, пагинация Pagy
**Цель:** покупатель видит каталог и категории постранично (US-03, US-04).

**Задачи:**
- [ ] Добавить гем `pagy` (актуальная стабильная версия), подключить по README **установленной** версии. API отличается между мажорными версиями: в 9.x это `Pagy::Backend` / `Pagy::Frontend` и `pagy_nav`, в новых версиях `Pagy::Method` и методы объекта `@pagy`. Настроить лимит 12 и стили Tailwind.
- [ ] `ProductsController#index` (`allow_unauthenticated_access`): `Product.active.includes(:category).with_attached_image.newest` + Pagy.
- [ ] `CategoriesController#show` по slug: тот же партиал каталога, в нём только товары категории. 404 для неизвестного slug.
- [ ] Партиал `products/_product` (карточка), `products/_catalog` (сетка + пагинация внутри `turbo_frame_tag "products"`).
- [ ] Главная: категории с количеством товаров, 8 новинок (US-03).
- [ ] Подключить Pagy в `Admin::ProductsController`.

**Тесты:**
- `ProductTest`: scopes `newest`, `active`.
- `ProductsControllerTest`: 200, нет скрытых товаров, пагинация (`page=2`).
- `CategoriesControllerTest`: фильтрация, 404.
- System `CatalogBrowsingTest`: главная → категория → страница 2.

**Коммиты:** `chore: add pagy gem` · `feat: add public catalog with pagination` · `feat: show categories and new arrivals on home page`

---

## Этап 8. Поиск, фильтры и сортировка
**Цель:** покупатель находит товары по запросу, цене и наличию (US-05, US-06).

**Задачи:**
- [ ] Scopes `search`, `in_category`, `price_from`, `price_to`, `in_stock`, `sorted_by` и композиция `filter_by(params)` в `Product` по [ERD §2.4](ERD.md#24-products). Вся логика живёт в модели, контроллер только вызывает `Product.active.filter_by(filter_params)`.
- [ ] Безопасная обработка параметров: `sanitize_sql_like`, приведение цены через `BigDecimal(value, exception: false)`, белый список ключей сортировки.
- [ ] Поиск в шапке ведёт на `products_path(q:)`.
- [ ] Боковая панель фильтров: форма с `data-turbo-frame="products"` и `data-turbo-action="advance"`, автоотправка при смене сортировки (небольшой Stimulus-контроллер `auto_submit`).
- [ ] Текст «Найдено: N», пустое состояние, «Сбросить».

**Тесты:**
- `ProductTest`: каждый scope отдельно и в комбинации, регистронезависимость, экранирование `%`, некорректная цена игнорируется, неизвестная сортировка даёт `newest`.
- `ProductsControllerTest`: параметры фильтров, ответ на запрос Turbo Frame.
- System `SearchTest`, `FilterTest`: ввести запрос и фильтры, проверить результаты и URL.

**Коммиты:** `feat: add product search and filter scopes` · `feat: add catalog filters sidebar with Turbo Frame` · `test: cover search and filters`

---

## Этап 9. Страница товара
**Цель:** подробная карточка товара (US-07).

**Задачи:**
- [ ] `ProductsController#show` по slug, только активные (иначе 404).
- [ ] Представление по [WIREFRAMES §4](WIREFRAMES.md#4-страница-товара-productsslug): breadcrumbs, наличие, поле количества, «Другие товары категории».
- [ ] Для гостя ссылка «Войдите, чтобы купить». Форма «В корзину» пока ведёт на будущий маршрут (кнопку активируем на этапе 10).

**Тесты:** `ProductsControllerTest#show` (200, 404 для скрытого), system `ProductPageTest`.

**Коммиты:** `feat: add product page`

---

## Этап 10. Корзина: модели и добавление товара
**Цель:** авторизованный покупатель кладёт товар в корзину (US-08).

**Задачи:**
- [ ] `bin/rails g model Cart user:references` (уникальный индекс `user_id`), `bin/rails g model CartItem cart:references product:references quantity:integer` (default 1, check `> 0`, уникальный `[cart_id, product_id]`).
- [ ] `User#cart!`, `Cart#add_product`, `#total`, `#items_count`, `CartItem#subtotal`, валидация остатка по [ERD §2.5–2.6](ERD.md#25-carts).
- [ ] `Product`: `has_many :cart_items, dependent: :destroy`.
- [ ] `CartItemsController#create` (требует входа): `Current.user.cart!.add_product(product, quantity)`. Ответы: `turbo_stream` (обновить `cart_counter` и `flash`) и `html` (редирект назад).
- [ ] Счётчик корзины в шапке (`id="cart_counter"`).
- [ ] Включить кнопки «В корзину» на карточке и странице товара.

**Тесты:**
- `CartTest`: добавление нового товара, увеличение количества, превышение остатка → ошибка, неактивный товар, `total`, `items_count`.
- `CartItemTest`: валидации количества и уникальности.
- `CartItemsControllerTest`: гость → редирект на вход; customer → turbo_stream-ответ, счётчик.
- System `AddToCartTest`: войти → каталог → «В корзину» → счётчик = 1.

**Коммиты:** `feat: add Cart and CartItem models` · `feat: add product to cart with Turbo Stream counter update` · `test: cover cart logic`

---

## Этап 11. Корзина: страница, изменение количества, удаление
**Цель:** покупатель управляет корзиной без перезагрузки страницы (US-09).

**Задачи:**
- [ ] `resource :cart, only: :show`, `resources :cart_items, only: %i[create update destroy]`.
- [ ] `CartsController#show`. `CartItemsController#update/destroy` ищет позицию через `Current.user.cart!.cart_items.find(params[:id])` (чужая даёт 404).
- [ ] Партиалы `cart_items/_cart_item` (с `dom_id`), `carts/_summary`. Turbo Stream-шаблоны `update.turbo_stream.erb`, `destroy.turbo_stream.erb`.
- [ ] `Cart#checkout_ready?`, `#unavailable_items` и предупреждения в корзине.
- [ ] Пустое состояние.

**Тесты:**
- `CartTest`: `checkout_ready?`, `unavailable_items`.
- `CartItemsControllerTest`: update (валидное и невалидное количество), destroy, чужой item → 404, формат turbo_stream.
- System `CartManagementTest`: «+» → сумма изменилась; удалить → строки нет; корзина пуста → пустое состояние.

**Коммиты:** `feat: add cart page` · `feat: update and remove cart items via Turbo Streams` · `test: cover cart management`

---

## Этап 12. Заказы: модели и транзакция оформления
**Цель:** надёжная бизнес-логика заказа в моделях, пока без UI (US-10).

**Задачи:**
- [ ] `bin/rails g model Order user:references number:string:uniq status:integer total:decimal{10,2} full_name phone address:text comment:text` — ограничения по [ERD §2.7](ERD.md#27-orders).
- [ ] `bin/rails g model OrderItem order:references product:references product_name unit_price:decimal{10,2} quantity:integer` — ограничения по [ERD §2.8](ERD.md#28-order_items).
- [ ] `Order`: enum статусов, `TRANSITIONS`, `assign_number`, валидации, `place_from_cart!` по [ERD §4](ERD.md#4-транзакция-оформления-заказа-orderplace_from_cart), `can_transition_to?`, `available_transitions`, `transition_to!`, `cancel!`, scopes `recent`, `not_cancelled`, `revenue`.
- [ ] Классы ошибок `Order::EmptyCartError`, `Order::InsufficientStockError` (с товаром в сообщении).
- [ ] `User`: `has_many :orders, dependent: :restrict_with_error`. `Product`: `has_many :order_items, dependent: :restrict_with_error`.

**Тесты (главный блок проекта):**
- `OrderTest.place_from_cart!`:
  - успех: заказ создан, позиции созданы, `unit_price` и `product_name` скопированы, `stock` уменьшен, корзина пуста, `total` верный;
  - нехватка остатка: исключение, `Order.count`, `OrderItem.count` и `stock` не изменились, корзина цела;
  - пустая корзина → `EmptyCartError`;
  - изменение `product.price` после заказа не меняет `order_item.unit_price`;
  - невалидные данные доставки → `RecordInvalid` и откат остатков.
- `OrderTest`: генерация уникального номера, переходы (все разрешённые и запрещённые), `cancel!` возвращает остатки, повторный `cancel!` запрещён.
- `OrderItemTest`: `subtotal`, валидации.

**Коммиты:** `feat: add Order and OrderItem models` · `feat: place order from cart in a transaction with stock locking` · `feat: add order status transitions and cancellation` · `test: cover order placement and transitions`

---

## Этап 13. Оформление заказа (UI)
**Цель:** покупатель оформляет заказ через интерфейс (US-10).

**Задачи:**
- [ ] `resources :orders, only: %i[index show new create]`.
- [ ] `OrdersController#new`: если корзина пуста или не готова к оформлению, редирект в корзину. ФИО предзаполняется из `Current.user.full_name`.
- [ ] `#create`: `Order.place_from_cart!(cart, order_params)`. Обработка `InsufficientStockError` → редирект в корзину с alert, `RecordInvalid` → `render :new, status: :unprocessable_content`.
- [ ] `#show`: `Current.user.orders.find(params[:id])` — страница подтверждения и деталей.
- [ ] Защита от двойной отправки (`data-turbo-submits-with`).

**Тесты:**
- `OrdersControllerTest`: new с пустой корзиной → редирект; create успех → редирект на show; ошибки → 422; нехватка → редирект в корзину; show чужого → 404.
- System `CheckoutTest`: полный путь «вход → каталог → в корзину → оформить → заказ создан, остаток уменьшился».

**Коммиты:** `feat: add checkout form and order confirmation page` · `test: add end-to-end checkout system test`

---

## Этап 14. Личный кабинет: история заказов
**Цель:** покупатель видит свои заказы (US-11).

**Задачи:**
- [ ] `OrdersController#index`: `Current.user.orders.recent.includes(:order_items)` + Pagy.
- [ ] `OrdersHelper#status_badge`, переводы статусов в `ru.yml`.
- [ ] Ссылка «Мои заказы» в меню, пустое состояние.
- [ ] *(Could)* Отмена своего заказа в статусе `pending`: `PATCH /orders/:id/cancel` → `order.cancel!`.

**Тесты:** `OrdersControllerTest#index` (только свои, пагинация), helper test `status_badge`, system `OrderHistoryTest`.

**Коммиты:** `feat: add customer order history` · `test: cover order history`

---

## Этап 15. Админ: управление заказами и статусами
**Цель:** админ обрабатывает заказы (US-14).

**Задачи:**
- [ ] `Admin::OrdersController` (index с фильтром `status` и Pagy, show, update). `resources :orders, only: %i[index show update]` в namespace admin.
- [ ] `update`: `order.transition_to!(params[:status])` → ответ `turbo_stream` (замена `order_status` и `flash`). Недопустимый переход → alert, статус не меняется.
- [ ] Вкладки-фильтры со счётчиками (`Order.group(:status).count`).
- [ ] Представления по [WIREFRAMES §13](WIREFRAMES.md#13-админ-заказы).

**Тесты:**
- `Admin::OrdersControllerTest`: фильтр, допустимый и недопустимый переход, отмена возвращает остатки, customer → запрет.
- System `AdminOrdersTest`: открыть заказ → «Отметить оплаченным» → бейдж поменялся без перезагрузки.

**Коммиты:** `feat: add admin orders list with status filter` · `feat: change order status via Turbo Streams` · `test: cover admin order management`

---

## Этап 16. Админ: дашборд *(Could)*
**Цель:** сводка по магазину (US-15).

**Задачи:** карточки статистики (`Order.group(:status).count`, `Order.revenue`), список `Product.low_stock`, последние 5 заказов.

**Тесты:** `Admin::DashboardControllerTest`, `ProductTest#low_stock`, `OrderTest#revenue`.

**Коммиты:** `feat: add admin dashboard with store statistics`

---

## Этап 17. Seeds с демо-данными
**Цель:** проект наполняется данными для демонстрации одной командой.

**Задачи:**
- [ ] `db/seeds.rb` идемпотентный (`find_or_create_by!`): `admin@example.com` (admin), `customer@example.com` (customer), пароль `password123`.
- [ ] 6–8 категорий и 40–60 товаров с разными ценами и остатками (включая 0 и неактивные). Изображения берутся из `db/seeds/images/` (небольшие файлы в репозитории).
- [ ] 3–5 заказов у демо-покупателя в разных статусах (через `Order.place_from_cart!`, чтобы данные были консистентны).

**Тесты:** `bin/rails db:reset` выполняется без ошибок дважды подряд, есть smoke-тест `SeedsTest` (опционально).

**Коммиты:** `chore: add demo seeds`

---

## Этап 18. Полировка интерфейса
**Цель:** аккуратный и цельный внешний вид.

**Задачи:**
- [ ] Пройти все страницы на ширинах 375px, 768px и 1280px, исправить вёрстку.
- [ ] Страницы `public/404.html`, `public/422.html`, `public/500.html` в стиле магазина.
- [ ] Единые кнопки, формы, бейджи и пустые состояния. Фокус-состояния и `alt` у изображений (доступность).
- [ ] Проверить N+1 в логах на основных страницах.
- [ ] Проверить, что все строки интерфейса взяты из `ru.yml` и захардкоженного русского текста во view нет.

**Коммиты:** `style: polish responsive layout` · `style: add custom error pages`

---

## Этап 19. Финальная проверка и сдача
**Цель:** проект готов к защите.

**Задачи:**
- [ ] Полный прогон: `bin/rails test`, `bin/rails test:system`, `bin/rubocop`, `bin/brakeman` (или `bin/ci`).
- [ ] Пройти все User Stories с приоритетом Must по критериям приемки вручную, отметить в чек-листе.
- [ ] `README.md`: описание, стек, требования, установка (`bin/setup`, `bin/rails db:seed`, `bin/dev`), демо-аккаунты, запуск тестов, ссылки на `docs/`.
- [ ] Сценарий демо (5–7 минут):
  1. гость: главная → поиск → фильтр → товар;
  2. регистрация → корзина → изменение количества → оформление → заказ в ЛК;
  3. вход админом → новый заказ → смена статусов → отмена с возвратом остатка;
  4. CRUD товара с изображением;
  5. попытка customer открыть `/admin` → отказ;
  6. показать тесты и историю Git.
- [ ] Тег `v1.0.0`, обновить статусы в таблице раздела 2.

**Коммиты:** `docs: add README with setup and demo instructions` · `chore: release v1.0.0`

**DoD:** чек-лист из [PROJECT_SPEC §8](PROJECT_SPEC.md#8-критерии-готовности-проекта-к-сдаче) закрыт.

---

## 3. Карта тестов

| Слой | Расположение | Что проверяем |
|---|---|---|
| Модели (Unit) | `test/models/*_test.rb` | валидации, scopes, `Cart#add_product`, `Order.place_from_cart!`, переходы статусов, `cancel!` |
| Хелперы | `test/helpers/*_test.rb` | формат цены, бейдж статуса |
| Контроллеры (Integration) | `test/controllers/**/*_test.rb` | доступ по ролям, редиректы, коды ответов, Turbo Stream-ответы, скоупинг чужих данных |
| System (Feature) | `test/system/*_test.rb` | регистрация и вход, каталог, поиск и фильтры, корзина, оформление, ЛК, админ: категории, товары, заказы |

Минимальная цель — каждая User Story закрыта хотя бы одним system- или integration-тестом, а вся бизнес-логика в моделях покрыта unit-тестами.

## 4. Риски и решения

| Риск | Решение |
|---|---|
| Гонка при одновременной покупке последнего товара | `lock!` в транзакции, блокировки в порядке `product_id`, check constraint `stock >= 0` |
| Slug из кириллицы получается пустым | правило транслитерации в `ru.yml`; fallback на `sku` / `id` |
| System-тесты не запускаются в WSL | установленный Chrome или Chromium; headless-режим; при проблемах `driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1000]` |
| Pagy поменял API между версиями | следовать README установленной версии, зафиксировать версию в `Gemfile.lock` |
| Конфликты при параллельной работе команды | короткие ветки на этап, частый `git pull` из `main`, миграции создаются только в своей ветке |
| Turbo «съедает» ошибки форм | рендерить ошибки с `status: :unprocessable_content` |
