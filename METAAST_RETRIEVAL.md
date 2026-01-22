# MetaAST-Enhanced Retrieval

Phase 5B implementation for Ragex RAG system.

## Overview

MetaAST-enhanced retrieval leverages semantic metadata from the Metastatic analyzer to improve code search accuracy and relevance. This system combines:

- **Context-aware ranking** based on query intent
- **Cross-language semantic search** for finding equivalent constructs
- **Query expansion** with domain-specific synonyms
- **Purity and complexity analysis** for code quality ranking

## Architecture

### Core Components

1. **MetaASTRanker** (`lib/ragex/retrieval/metaast_ranker.ex`)
   - Calculates ranking boosts based on MetaAST metadata
   - Implements context-aware intent detection
   - Provides semantic equivalence checking

2. **CrossLanguage** (`lib/ragex/retrieval/cross_language.ex`)
   - Cross-language construct search
   - Pattern-based implementation finding
   - Alternative code suggestions

3. **QueryExpansion** (`lib/ragex/retrieval/query_expansion.ex`)
   - Automatic query expansion with synonyms
   - Cross-language term injection
   - Query variation generation

### Integration Points

- **Hybrid Search**: All three strategies (semantic_first, graph_first, fusion) apply MetaAST ranking
- **MCP Tools**: Four new tools expose MetaAST functionality
- **RAG Pipeline**: Query expansion can enhance retrieval context

## Ranking System

### Boost Calculation

MetaAST metadata influences search result ranking through multiplicative boosts:

```elixir
# Base boost factors
boost_core = 1.2          # M2.1 Core constructs
boost_pure = 1.3          # Pure functions
complexity_penalty = 0.02  # Per complexity unit
native_penalty = 0.9       # M2.3 Native constructs
```

**Example**: A pure, core-level function with complexity 2:
```
boost = 1.0 × 1.2 (core) × 1.3 (pure) × (1 - 0.04) = 1.4976
final_score = base_score × 1.4976
```

### Context-Aware Ranking

Query intent modifies boost parameters automatically:

| Intent | Boost Core | Boost Pure | Complexity Penalty | Native Penalty |
|--------|-----------|------------|-------------------|----------------|
| **explain** | 1.5 | 1.4 | 0.03 | 0.8 |
| **refactor** | 1.0 | 0.8 | -0.01 | 1.2 |
| **example** | 1.3 | 1.1 | 0.01 | 1.1 |
| **debug** | 0.9 | 0.7 | -0.02 | 1.3 |
| **general** | 1.2 | 1.3 | 0.02 | 0.9 |

**Intent Detection**: Automatically triggered by query keywords:
- `"explain how"` → `:explain` (prefer simple, pure code)
- `"refactor this"` → `:refactor` (prefer complex, improvable code)
- `"show example"` → `:example` (prefer diverse examples)
- `"fix bug"` → `:debug` (prefer code with side effects)

### Usage

```elixir
# Automatic intent detection
Hybrid.search("explain how map works", strategy: :fusion)

# Explicit intent
Hybrid.search("find map", metaast_opts: [intent: :example])

# Disable MetaAST ranking
Hybrid.search("find map", metaast_ranking: false)

# Custom boost parameters
Hybrid.search("find map", metaast_opts: [
  boost_core: 1.5,
  boost_pure: 1.4,
  complexity_penalty: 0.03
])
```

## Cross-Language Search

### Finding Equivalent Constructs

Search for semantically equivalent code across languages:

```elixir
alias Ragex.Retrieval.CrossLanguage

# Find Python/JavaScript equivalents of Elixir Enum.map
{:ok, results} = CrossLanguage.search_equivalent(
  :elixir,
  {:Enum, :map, 2},
  [:python, :javascript]
)

# Results grouped by language:
# %{
#   python: [list_comprehension, map_builtin, ...],
#   javascript: [Array.map, lodash.map, ...]
# }
```

### Pattern-Based Search

Find all implementations of a MetaAST pattern:

```elixir
# Find all map/transform operations across all languages
pattern = {:collection_op, :map, :_, :_}
{:ok, results} = CrossLanguage.find_all_implementations(pattern)

# Find lambda functions in specific languages
pattern = {:lambda, :_, :_, :_}
{:ok, results} = CrossLanguage.find_all_implementations(
  pattern,
  languages: [:elixir, :python],
  limit: 50
)
```

### Suggesting Alternatives

Generate cross-language code suggestions:

```elixir
source = %{
  language: :python,
  code: "[x * 2 for x in items]",
  meta_ast: {:collection_op, :map, ...}
}

{:ok, suggestions} = CrossLanguage.suggest_alternatives(
  source,
  [:elixir, :javascript]
)

# Returns:
# [
#   %{language: :elixir, code_sample: "Enum.map(items, &(&1 * 2))", ...},
#   %{language: :javascript, code_sample: "items.map(x => x * 2)", ...}
# ]
```

## Query Expansion

### Automatic Expansion

Enhance queries with semantic synonyms and cross-language terms:

```elixir
alias Ragex.Retrieval.QueryExpansion

# Basic expansion
QueryExpansion.expand("find map function")
# => "find map function collection transform iterate"

# With intent
QueryExpansion.expand("explain error handling", intent: :explain)
# => "explain error handling simple clear understand basic exception"

# Limit expansion
QueryExpansion.expand("map", max_terms: 3)
# => "map transform apply convert"
```

### Construct Synonyms

Built-in synonym mapping for common constructs:

| Construct | Synonyms |
|-----------|----------|
| **map** | transform, apply, convert, iterate |
| **filter** | select, where, predicate, choose |
| **reduce** | fold, accumulate, aggregate, combine |
| **loop** | iterate, repeat, cycle, while |
| **lambda** | anonymous, closure, arrow, inline |
| **pure** | immutable, referential, deterministic, safe |

### Cross-Language Terms

Automatic cross-language term injection:

| Term | Cross-Language Equivalents |
|------|---------------------------|
| **comprehension** (Python) | map, filter, select, transform |
| **promise** (JavaScript) | future, async, deferred, task |
| **pipe** (Elixir) | chain, compose, flow, thread |
| **arrow** (JavaScript) | lambda, anonymous, closure |

### Query Variations

Generate alternative query phrasings:

```elixir
QueryExpansion.suggest_variations("find map")
# => [
#   "find map collection",
#   "find map transform",
#   "find map iterate",
#   "find map over items"
# ]
```

### Result Enrichment

Extract features from search results for iterative refinement:

```elixir
# Initial search
{:ok, results} = Hybrid.search("map")

# Extract semantic features from results
features = QueryExpansion.extract_features_from_results(results)
# => ["collection", "transform", "iterate", "apply", ...]

# Enrich original query
enriched = QueryExpansion.enrich_query("map", features, max_features: 3)
# => "map collection transform iterate"

# Search again with enriched query
{:ok, refined_results} = Hybrid.search(enriched)
```

## MCP Tools

### metaast_search

Search for semantically equivalent constructs across languages.

**Parameters**:
- `source_language`: Source language (`"elixir"`, `"python"`, etc.)
- `source_construct`: Construct to search (e.g., `"Enum.map/2"`)
- `target_languages`: Array of target languages (empty = all)
- `limit`: Max results per language (default: 5)
- `threshold`: Similarity threshold 0.0-1.0 (default: 0.6)
- `strict_equivalence`: Require exact AST match (default: false)

**Example**:
```json
{
  "tool": "metaast_search",
  "arguments": {
    "source_language": "elixir",
    "source_construct": "Enum.map/2",
    "target_languages": ["python", "javascript"],
    "limit": 5
  }
}
```

### cross_language_alternatives

Suggest cross-language alternatives for code.

**Parameters**:
- `language`: Source language
- `code`: Code snippet or description
- `target_languages`: Languages for alternatives (empty = all)

**Example**:
```json
{
  "tool": "cross_language_alternatives",
  "arguments": {
    "language": "python",
    "code": "[x * 2 for x in items]",
    "target_languages": ["elixir", "javascript"]
  }
}
```

### expand_query

Expand search query with semantic synonyms and cross-language terms.

**Parameters**:
- `query`: Original query string
- `intent`: Query intent (optional, auto-detected)
- `max_terms`: Max expansion terms (default: 5)
- `include_synonyms`: Include construct synonyms (default: true)
- `include_cross_language`: Include cross-language terms (default: true)

**Example**:
```json
{
  "tool": "expand_query",
  "arguments": {
    "query": "find map function",
    "intent": "explain",
    "max_terms": 5
  }
}
```

**Response**:
```json
{
  "status": "success",
  "original_query": "find map function",
  "expanded_query": "find map function simple clear collection transform",
  "suggested_variations": [
    "find map collection",
    "find map transform",
    "find map over items"
  ]
}
```

### find_metaast_pattern

Find all implementations of a MetaAST pattern.

**Parameters**:
- `pattern`: Pattern string (e.g., `"collection_op:map"`, `"lambda"`)
- `languages`: Filter by languages (empty = all)
- `limit`: Max results (default: 20)

**Pattern Format**:
- `"collection_op:map"` → Map/transform operations
- `"collection_op:filter"` → Filter/select operations
- `"loop:for"` → For loops
- `"lambda"` → Lambda/anonymous functions
- `"conditional"` → If/else conditionals

**Example**:
```json
{
  "tool": "find_metaast_pattern",
  "arguments": {
    "pattern": "collection_op:map",
    "languages": ["elixir", "python"],
    "limit": 10
  }
}
```

## Best Practices

### When to Use MetaAST Ranking

**Use MetaAST ranking when**:
- Searching for code with specific quality characteristics
- Looking for simple, understandable examples
- Finding refactoring candidates
- Need cross-language equivalents

**Disable MetaAST ranking when**:
- Exact keyword matching is required
- MetaAST metadata is unavailable
- Performance is critical (minimal overhead, but measurable)

### Query Expansion Guidelines

1. **Use intent specification** for targeted searches:
   ```elixir
   QueryExpansion.expand("map", intent: :explain)  # For learning
   QueryExpansion.expand("map", intent: :refactor) # For improvements
   ```

2. **Limit expansion terms** to avoid dilution:
   ```elixir
   QueryExpansion.expand("map", max_terms: 3)
   ```

3. **Iterative refinement** for complex searches:
   ```elixir
   # 1. Initial search
   {:ok, results1} = Hybrid.search("map")
   
   # 2. Extract features
   features = QueryExpansion.extract_features_from_results(results1)
   
   # 3. Refine query
   enriched = QueryExpansion.enrich_query("map", features)
   
   # 4. Search again
   {:ok, results2} = Hybrid.search(enriched)
   ```

### Cross-Language Search Tips

1. **Start broad, then narrow**:
   ```elixir
   # Broad: All languages
   CrossLanguage.search_equivalent(:elixir, "Enum.map/2", [])
   
   # Narrow: Specific languages
   CrossLanguage.search_equivalent(:elixir, "Enum.map/2", [:python])
   ```

2. **Use patterns for exploration**:
   ```elixir
   # Find all implementations of a concept
   pattern = {:collection_op, :map, :_, :_}
   CrossLanguage.find_all_implementations(pattern)
   ```

3. **Adjust threshold for precision**:
   ```elixir
   # Strict matching
   CrossLanguage.search_equivalent(
     :elixir, "Enum.map/2", [:python],
     threshold: 0.9, strict_equivalence: true
   )
   
   # Loose matching
   CrossLanguage.search_equivalent(
     :elixir, "Enum.map/2", [:python],
     threshold: 0.5
   )
   ```

## Performance Considerations

### Ranking Overhead

MetaAST ranking adds minimal overhead:
- **Without MetaAST**: ~10ms for 100 results
- **With MetaAST**: ~12ms for 100 results (~20% overhead)

Overhead scales linearly with result count.

### Query Expansion

Query expansion is performed once per query:
- **Expansion time**: <1ms (pure computation)
- **Search time impact**: Minimal (broader query may return more candidates)

### Cross-Language Search

Cross-language search scales with:
- Number of target languages
- Number of nodes per language
- Complexity of AST comparison

**Optimization**: Use language filters to limit search space:
```elixir
# Slower: All languages
CrossLanguage.search_equivalent(:elixir, "Enum.map/2", [])

# Faster: Specific languages
CrossLanguage.search_equivalent(:elixir, "Enum.map/2", [:python])
```

## Configuration

### Hybrid Search Options

```elixir
Hybrid.search("query", [
  # Enable/disable MetaAST ranking
  metaast_ranking: true,
  
  # MetaAST-specific options
  metaast_opts: [
    # Query intent (optional, auto-detected)
    intent: :explain,
    
    # Boost parameters
    boost_core: 1.2,
    boost_pure: 1.3,
    complexity_penalty: 0.02,
    native_penalty: 0.9,
    
    # Cross-language options
    cross_language: false
  ]
])
```

### Query Expansion Options

```elixir
QueryExpansion.expand("query", [
  # Query intent
  intent: :explain,
  
  # Expansion limits
  max_terms: 5,
  
  # Feature toggles
  include_synonyms: true,
  include_cross_language: true
])
```

### Cross-Language Options

```elixir
CrossLanguage.search_equivalent(
  source_language,
  source_construct,
  target_languages,
  [
    # Result limits
    limit: 5,
    
    # Matching options
    threshold: 0.6,
    strict_equivalence: false,
    include_source: false
  ]
)
```

## Examples

### Example 1: Finding Simple Examples

```elixir
# Search with explain intent for simple code
{:ok, results} = Hybrid.search(
  "explain how map works",
  strategy: :fusion,
  metaast_opts: [intent: :explain]
)

# Results ranked by:
# 1. Core-level constructs (1.5x boost)
# 2. Pure functions (1.4x boost)
# 3. Low complexity (0.03 penalty per unit)
```

### Example 2: Refactoring Candidates

```elixir
# Find complex, impure code to refactor
{:ok, results} = Hybrid.search(
  "find authentication code",
  metaast_opts: [intent: :refactor]
)

# Results ranked by:
# 1. Higher complexity (negative penalty = boost)
# 2. Impure functions (lower pure boost)
# 3. Native constructs (boosted instead of penalized)
```

### Example 3: Cross-Language Learning

```elixir
# Find how list comprehensions work across languages
pattern = {:collection_op, :map, :_, :_}

{:ok, results} = CrossLanguage.find_all_implementations(
  pattern,
  languages: [:python, :javascript, :elixir],
  limit: 5
)

# Group by language to see equivalent patterns
groups = CrossLanguage.group_by_equivalence(results)
```

### Example 4: Iterative Query Refinement

```elixir
# Start with broad query
query = "error handling"

# Expand query
expanded = QueryExpansion.expand(query, intent: :example)
# => "error handling sample usage demo code exception"

# Search with expanded query
{:ok, results} = Hybrid.search(expanded, limit: 20)

# Extract features from results
features = QueryExpansion.extract_features_from_results(results)
# => ["exception", "try", "catch", "rescue", ...]

# Create refined query
refined = QueryExpansion.enrich_query(query, features, max_features: 3)
# => "error handling exception try catch"

# Final search with refined query
{:ok, final_results} = Hybrid.search(refined, limit: 10)
```

## Limitations

1. **MetaAST Availability**: Requires code analyzed with Metastatic analyzer
2. **Language Support**: Currently supports Elixir, Erlang, Python, JavaScript
3. **AST Comparison**: Simple structural matching (not deep semantic analysis)
4. **Pattern Matching**: Limited to predefined MetaAST constructs
5. **Query Expansion**: Keyword-based (no NLP or LLM-powered expansion)

## Future Enhancements

Potential improvements for future phases:

1. **Deep Semantic Analysis**: Use LLM to understand code intent beyond AST structure
2. **Learning Ranking**: Adapt boost parameters based on user feedback
3. **More Languages**: Go, Rust, Java, C++, etc.
4. **Advanced Patterns**: Complex multi-node patterns with relationships
5. **Context Extraction**: Use surrounding code context for better equivalence matching
6. **LLM Query Expansion**: Use AI to generate high-quality query expansions

## Related Documentation

- [ALGORITHMS.md](ALGORITHMS.md) - Graph algorithms and PageRank
- [STREAMING.md](STREAMING.md) - Streaming AI responses
- [CONFIGURATION.md](CONFIGURATION.md) - System configuration
- [PERSISTENCE.md](PERSISTENCE.md) - Embedding caching
- [WARP.md](WARP.md) - Development guidelines
