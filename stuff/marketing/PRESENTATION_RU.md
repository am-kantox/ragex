# Ragex: Гибридный RAG для Анализа Кодовых Баз

## Введение

В эпоху, когда искусственный интеллект пытается научиться читать код лучше, чем это делают люди (что, надо признать, не так уж и сложно), появился **Ragex** — MCP-сервер для семантического анализа кодовых баз с элементами чёрной магии и машинного обучения. Проект написан на Elixir, потому что функциональное программирование — это как йога для мозга: сложно в начале, но потом понимаешь, что всё остальное было неправильным.

Ragex — это попытка объединить статический анализ кода с векторными представлениями и графами знаний. В результате получается система, которая может ответить на вопросы типа "где у меня функция, которая парсит JSON?" не хуже, чем ваш коллега, который неделю назад это писал, но уже всё забыл.

## Философия Проекта

Три кита, на которых держится Ragex:

1. **Local-first**: Никаких внешних API. Всё работает локально. Ваш код не отправляется в облако на растерзание корпоративным серверам. Параноики оценят.

2. **Гибридный поиск**: Символьный анализ (AST) + семантический поиск (эмбеддинги) + графы знаний. Это как иметь три разных вида радара: один видит близко, другой далеко, третий вообще смотрит в прошлое.

3. **Производительность**: Запросы выполняются за <100ms. Потому что жизнь коротка, а ждать результатов анализа кода — это издевательство над собой.

## Архитектура

Ragex состоит из нескольких слоёв, каждый из которых старается не испортить работу остальных:

```
┌─────────────────────────────────────┐
│   MCP Server (JSON-RPC 2.0)         │
│   stdio + Unix Socket                │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       ▼                ▼
┌─────────────┐  ┌──────────────┐
│ Анализаторы │  │ Graph Store  │
│ (AST)       │  │ (ETS)        │
└──────┬──────┘  └──────┬───────┘
       │                │
       │         ┌──────┴───────┐
       │         ▼              ▼
       │   ┌──────────┐  ┌─────────────┐
       └──►│  Vector  │  │  Bumblebee  │
           │  Store   │  │  (ML Model) │
           └──────────┘  └─────────────┘
```

### Компоненты

**1. MCP Server**  
Реализация Model Context Protocol — протокола, который позволяет AI-ассистентам общаться с внешними инструментами. JSON-RPC 2.0 через stdio (для интеграции) и Unix-сокет (для интерактивного использования). 

**2. Анализаторы**  
Парсеры для Elixir, Erlang, Python, JavaScript/TypeScript. Каждый извлекает AST, модули, функции, вызовы. Elixir и Erlang используют нативные парсеры, Python вызывает через subprocess модуль `ast`, JavaScript использует регулярные выражения (потому что жизнь несправедлива).

**3. Graph Store**  
Граф знаний на основе ETS (Erlang Term Storage). Узлы: модули, функции, вызовы. Рёбра: `:calls`, `:imports`, `:defines`. Поверх графа работают алгоритмы: PageRank, поиск путей, метрики центральности, детекция сообществ.

**4. Embeddings & Vector Store**  
Локальная ML-модель (sentence-transformers/all-MiniLM-L6-v2) через Bumblebee. Генерирует 384-мерные векторные представления для каждой функции и модуля. Косинусная близость для семантического поиска. Всё работает без интернета.

**5. Hybrid Retrieval**  
Reciprocal Rank Fusion (RRF) — алгоритм объединения результатов символьного и семантического поиска. Три стратегии: fusion (RRF), semantic-first, graph-first.

**6. Editor System**  
Безопасное редактирование кода с атомарными операциями, бэкапами, валидацией синтаксиса, форматированием. Поддержка multi-file транзакций и семантического рефакторинга через AST.

## Use Cases: Когда Это Вообще Нужно?

### 1. Семантический Поиск по Кодовой Базе

**Проблема**: Вы помните, что где-то была функция для работы с HTTP-запросами, но где именно — забыли. Название тоже не помните. Grep не поможет.

**Решение**: Семантический поиск на естественном языке.

```elixir
# Подключаемся к Ragex
alias Ragex.VectorStore

# Ищем функцию
{:ok, results} = VectorStore.search("HTTP request handler", 
  limit: 5, 
  threshold: 0.7,
  node_type: :function
)

# Результаты отсортированы по релевантности
Enum.each(results, fn {node, similarity} ->
  IO.puts("#{node.name} (#{similarity})")
  IO.puts("  File: #{node.metadata.file}")
  IO.puts("  Line: #{node.metadata.line}")
end)
```

**Что происходит внутри:**
1. Ваш запрос превращается в 384-мерный вектор
2. Вычисляется косинусная близость со всеми функциями в графе
3. Результаты фильтруются по порогу и типу узла
4. Возвращается топ-5

**Производительность**: <50ms для 100 сущностей.

### 2. Анализ Зависимостей и Вызовов

**Проблема**: Нужно понять, откуда вызывается функция `process_data/2`, и что она сама вызывает. Рефакторинг без этой информации — русская рулетка.

**Решение**: Граф вызовов.

```elixir
alias Ragex.Graph.Store
alias Ragex.Graph.Algorithms

# Найти все функции, которые вызывают process_data/2
callers = Store.get_callers({:function, "MyModule.process_data/2"})

IO.puts("Callers:")
Enum.each(callers, fn caller ->
  IO.puts("  - #{caller.id}")
end)

# Найти все функции, которые вызывает process_data/2
callees = Store.get_callees({:function, "MyModule.process_data/2"})

IO.puts("\nCallees:")
Enum.each(callees, fn callee ->
  IO.puts("  - #{callee.id}")
end)

# Найти все пути между двумя функциями (с лимитом)
paths = Algorithms.find_all_paths(
  {:function, "MyModule.start/0"},
  {:function, "MyModule.process_data/2"},
  max_depth: 10,
  max_paths: 100
)

IO.puts("\nFound #{length(paths)} paths")
```

**Защита от плотных графов**: Если у узла >10 рёбер, Ragex предупредит о потенциальных проблемах с производительностью. Параметр `max_paths` предотвращает зависание на экспоненциальных взрывах.

### 3. Поиск "Бутылочных Горлышек" в Архитектуре

**Проблема**: Какие функции являются критичными для всей системы? Если они упадут — всё рухнет.

**Решение**: Betweenness Centrality (метрика центральности по посредничеству).

```elixir
alias Ragex.Graph.Algorithms

# Вычислить betweenness centrality для всех функций
scores = Algorithms.betweenness_centrality(
  max_nodes: 1000,
  normalize: true
)

# Отсортировать по убыванию
top_bottlenecks = scores
  |> Enum.sort_by(fn {_node, score} -> score end, :desc)
  |> Enum.take(10)

IO.puts("Top 10 bottleneck functions:")
Enum.each(top_bottlenecks, fn {node_id, score} ->
  IO.puts("  #{node_id}: #{Float.round(score, 4)}")
end)
```

**Применение**: Эти функции — ваши точки отказа. Их нужно покрыть тестами в первую очередь. Их изменение требует особой осторожности. Они же — кандидаты на рефакторинг и декомпозицию.

### 4. Детекция Архитектурных Модулей

**Проблема**: Код разросся, структура неочевидна. Хотелось бы понять, какие модули логически связаны и образуют кластеры.

**Решение**: Community Detection (алгоритм Louvain).

```elixir
alias Ragex.Graph.Algorithms

# Найти сообщества (кластеры модулей)
communities = Algorithms.detect_communities(
  algorithm: :louvain,
  hierarchical: true,
  resolution: 1.0
)

IO.puts("Found #{map_size(communities)} communities")

# Группировка по сообществам
grouped = Enum.group_by(communities, fn {_node, community} -> community end)

Enum.each(grouped, fn {community_id, members} ->
  IO.puts("\nCommunity #{community_id} (#{length(members)} nodes):")
  Enum.each(members, fn {node_id, _} ->
    IO.puts("  - #{node_id}")
  end)
end)
```

**Применение**: Визуализация архитектуры, планирование рефакторинга, выделение микросервисов.

### 5. Безопасный Рефакторинг

**Проблема**: Нужно переименовать функцию `old_function/2` в `new_function/2` во всём проекте. Ручной рефакторинг — это ошибки и страдания.

**Решение**: Семантический рефакторинг через AST.

```elixir
alias Ragex.Editor.Refactor

# Переименовать функцию во всём проекте
result = Refactor.rename_function(
  :MyModule,
  :old_function,
  :new_function,
  2,  # arity
  scope: :project,
  validate: true,
  format: true
)

case result do
  {:ok, details} ->
    IO.puts("Success! Updated files:")
    Enum.each(details.edited_files, &IO.puts("  - #{&1}"))
    
  {:error, reason} ->
    IO.puts("Rollback performed. Error: #{inspect(reason)}")
end
```

**Как это работает:**
1. Ragex находит все места, где вызывается `MyModule.old_function/2` (через граф знаний)
2. Парсит AST каждого файла
3. Заменяет узлы AST (не регулярками!)
4. Валидирует синтаксис
5. Форматирует код
6. Атомарно применяет изменения (или откатывает всё при ошибке)

### 6. Multi-File Транзакции

**Проблема**: Нужно одновременно изменить несколько файлов. Если хоть одно изменение невалидно — откатить всё.

**Решение**: Атомарные транзакции.

```elixir
alias Ragex.Editor.{Transaction, Types}

# Создать транзакцию
txn = Transaction.new(validate: true, format: true)
  |> Transaction.add("lib/module_a.ex", [
      Types.replace(10, 15, "def new_version do\n  :ok\nend")
    ])
  |> Transaction.add("lib/module_b.ex", [
      Types.insert(20, "@doc \"Updated documentation\"")
    ])
  |> Transaction.add("test/module_test.exs", [
      Types.replace(5, 5, "# Updated test")
    ])

# Применить все изменения атомарно
case Transaction.commit(txn) do
  {:ok, result} ->
    IO.puts("Edited #{result.files_edited} files successfully")
    
  {:error, result} ->
    IO.puts("Transaction rolled back!")
    IO.puts("Errors: #{inspect(result.errors)}")
end
```

**Гарантии:**
- Все файлы валидируются перед применением
- Создаются бэкапы для каждого файла
- При любой ошибке — автоматический откат всех изменений
- Бэкапы хранятся в `~/.ragex/backups/<project_hash>/`

## Интеграция с LunarVim

LunarVim — это Neovim на стероидах. Ragex интегрируется через MCP и предоставляет команды для семантического поиска прямо из редактора.

### Установка

1. Скопируйте конфигурационные файлы:

```bash
cp ragex/lvim.cfg/lua/user/*.lua ~/.config/lvim/lua/user/
```

2. Добавьте в `~/.config/lvim/config.lua`:

```lua
-- Ragex integration
local ragex = require("user.ragex")
local ragex_telescope = require("user.ragex_telescope")

-- Setup
ragex.setup({
  ragex_path = vim.fn.expand("~/Proyectos/Ammotion/ragex"),
  enabled = true,
  debug = false,
})

-- Keybindings (using "r" prefix)
lvim.builtin.which_key.mappings["r"] = {
  name = "Ragex",
  s = { function() ragex_telescope.ragex_search() end, "Semantic Search" },
  w = { function() ragex_telescope.ragex_search_word() end, "Search Word" },
  f = { function() ragex_telescope.ragex_functions() end, "Find Functions" },
  m = { function() ragex_telescope.ragex_modules() end, "Find Modules" },
  a = { function() ragex.analyze_current_file() end, "Analyze File" },
  d = { function() ragex.analyze_directory(vim.fn.getcwd()) end, "Analyze Directory" },
  c = { function() ragex.show_callers() end, "Find Callers" },
  r = { function()
      vim.ui.input({ prompt = "New name: " }, function(name)
        if name then ragex.rename_function(name) end
      end)
    end, "Rename Function" },
  g = { function() ragex.graph_stats() end, "Graph Stats" },
  b = { function() ragex.show_betweenness_centrality() end, "Betweenness" },
  n = { function() ragex.show_communities("louvain") end, "Communities" },
  e = { function() ragex.export_graph("graphviz") end, "Export Graph" },
}
```

### Использование

**Семантический поиск** (`<leader>rs`):
```
1. Нажмите <leader>rs
2. Введите запрос: "parse JSON response"
3. Выберите результат из Telescope
4. Ragex откроет файл на нужной строке
```

**Поиск функций** (`<leader>rf`):
```
Telescope откроет список всех функций в проекте с фильтрацией
```

**Анализ директории** (`<leader>rd`):
```
Ragex проанализирует всю директорию рекурсивно и обновит граф знаний
```

**Поиск вызовов** (`<leader>rc`):
```
Показывает все функции, которые вызывают текущую
```

**Рефакторинг** (`<leader>rr`):
```
Переименовать функцию под курсором (с обновлением всех вызовов)
```

**Граф-статистика** (`<leader>rg`):
```
Показывает статистику по графу: количество узлов, рёбер, плотность, топ по degree
```

**Betweenness Centrality** (`<leader>rb`):
```
Показывает функции-бутылочные горлышки в архитектуре
```

**Community Detection** (`<leader>rn`):
```
Визуализация архитектурных модулей и кластеров
```

### Пример Workflow

Типичный сценарий работы с Ragex в LunarVim:

```
1. Открыли проект: <leader>rd (анализировать директорию)
2. Нужно найти функцию: <leader>rs → "database connection"
3. Нашли функцию, открыли файл
4. Хотим узнать, кто вызывает: <leader>rc
5. Решили переименовать: <leader>rr → "connect_to_db"
6. Проверили статистику: <leader>rg
7. Экспортировали граф для визуализации: <leader>re
```

### Архитектура Интеграции

LunarVim общается с Ragex через Unix-сокет:

```
┌──────────────┐          ┌─────────────────┐
│   LunarVim   │          │  Ragex Server   │
│              │          │  (Unix Socket)  │
│   Lua Code   │──socat──►│ /tmp/ragex_mcp  │
│   Telescope  │◄─────────│      .sock      │
└──────────────┘          └─────────────────┘
```

Каждый запрос — это JSON-RPC 2.0 сообщение. Ответ парсится и показывается через Telescope picker или в floating window.

### Настройка Auto-Analyze

Ragex может автоматически анализировать код при сохранении файлов:

```lua
ragex.setup({
  auto_analyze = true,
  auto_analyze_on_start = true,
  auto_analyze_dirs = { "/path/to/project" },
})
```

**Инкрементальные обновления**: Ragex отслеживает изменения через SHA256-хеширование и перегенерирует эмбеддинги только для изменённых файлов (~5% при изменении одного файла).

## Performance & Caching

### Embeddings Cache

При первом запуске Ragex генерирует эмбеддинги для всех функций (~50 секунд на 1000 сущностей). Но:

1. **Автоматическое кеширование**: При выключении сервера кеш сохраняется
2. **Быстрый старт**: При следующем запуске <5 секунд (vs 50 без кеша)
3. **Инкрементальные обновления**: Только изменённые файлы перегенерируются
4. **Проект-специфичные кеши**: Каждый проект — свой кеш

```bash
# Статистика кеша
mix ragex.cache.stats

# Очистить кеш текущего проекта
mix ragex.cache.clear --current

# Принудительное обновление
mix ragex.cache.refresh --path /project/lib
```

### Память

- **ML-модель**: ~400 MB RAM
- **ETS-таблицы**: линейный рост, ~400 bytes на узел
- **Эмбеддинги**: ~400 bytes на вектор (384 float32)
- **Кеш-файлы**: ~15 MB на 1000 сущностей

### Производительность Запросов

| Операция | Время |
|----------|-------|
| Семантический поиск | <50ms (100 сущностей) |
| Граф-запрос | <10ms |
| Hybrid search (RRF) | <100ms |
| PageRank | <200ms (1000 узлов) |
| Betweenness centrality | <1s (1000 узлов, Brandes) |
| Community detection | <500ms (Louvain) |

## Production Features

### Поддержка Кастомных Embedding-Моделей

Ragex поддерживает 4 предконфигурированных модели:

```elixir
# config/config.exs
config :ragex, :embedding_model, "sentence-transformers/all-MiniLM-L6-v2"

# Альтернативы:
# - "sentence-transformers/all-MiniLM-L12-v2" (больше точность)
# - "sentence-transformers/paraphrase-MiniLM-L3-v2" (быстрее)
# - "sentence-transformers/multi-qa-MiniLM-L6-cos-v1" (для Q&A)
```

**Миграция моделей**:

```bash
mix ragex.embeddings.migrate --from old_model --to new_model
```

### File Watching

Автоматическое переиндексирование при изменении файлов:

```elixir
# Через MCP
{"method": "tools/call", "params": {
  "name": "watch_directory",
  "arguments": {"path": "/project/lib"}
}}

# В коде
Ragex.FileWatcher.watch("/project/lib")
```

### Экспорт Графа для Визуализации

```elixir
alias Ragex.Graph.Algorithms

# Graphviz DOT format
{:ok, dot} = Algorithms.export_graphviz(
  color_by: :betweenness,
  include_communities: true
)
File.write!("graph.dot", dot)

# Рендерим через Graphviz
System.cmd("dot", ["-Tpng", "graph.dot", "-o", "graph.png"])

# D3.js JSON format (для веб-визуализации)
{:ok, json} = Algorithms.export_d3_json(include_communities: true)
File.write!("graph.json", json)
```

Результат: красивый граф с цветовой кодировкой узлов по центральности, кластеризацией сообществ, и толщиной рёбер по весам вызовов.

## Ограничения и Подводные Камни

Потому что честность — лучшая политика:

1. **JavaScript/TypeScript анализатор**: Использует регулярные выражения. Работает на "простых" случаях. Для production-кода лучше добавить нормальный парсер.

2. **Семантический рефакторинг**: Пока только для Elixir. Erlang/Python/JS в планах, но не сегодня.

3. **Плотные графы**: Если у функции >100 вызовов, поиск путей может занять вечность. Используйте `max_paths` и `max_depth`.

4. **Память**: 400 MB для модели — это цена локального ML. Если RAM критична, можно отключить эмбеддинги (но зачем тогда вообще Ragex?).

5. **Cold start**: Первая генерация эмбеддингов занимает время. После этого — кеширование спасает.

## Заключение

Ragex — это попытка сделать анализ кода менее болезненным и более семантическим. Граф знаний + векторные эмбеддинги + алгоритмы на графах = инструмент, который может ответить на вопросы типа "где это используется?", "что это делает?", "почему всё сломалось?".

Проект написан на Elixir, потому что concurrency, fault-tolerance и паттерн-матчинг — это красиво. MCP-протокол, потому что AI-ассистенты — будущее (или настоящее, в зависимости от того, насколько вы параноик).

Интеграция с LunarVim превращает рефакторинг в нечто почти приятное. Семантический поиск работает, граф не врёт, рефакторинг не ломает код. Что ещё нужно?

Разумеется, это не серебряная пуля. Но, положа руку на сердце, серебряных пуль и не существует. Зато есть инструменты, которые делают жизнь разработчика чуть менее мучительной. Ragex — один из них.

---

**P.S.** Если после прочтения у вас возникло желание попробовать, запустите `./start_mcp.sh` и наслаждайтесь. Если что-то сломается — issue в GitHub. Если всё заработало — это, конечно, тоже можно написать в issue, но кто так делает?

**P.P.S.** Проект open-source, лицензия MIT. Делайте что хотите, на свой страх и риск. Автор не несёт ответственности за потерянное время, сломанный код и экзистенциальные кризисы, вызванные чтением чужих графов вызовов.

**Версия**: 0.2.0  
**Статус**: Production-ready (фазы 1-5, 8 завершены)  
**Язык**: Elixir 1.19+  
**Зависимости**: Erlang/OTP 27+, Python 3.x (опционально), Node.js (опционально)  
**Репозиторий**: https://github.com/am-kantox/ragex (или где там он у вас)
