#compdef mix
# Zsh completion for Ragex Mix tasks
# Install: copy to a directory in $fpath (e.g., /usr/local/share/zsh/site-functions/_ragex)

_ragex_tasks() {
    local -a tasks
    tasks=(
        'ragex.cache.clear:Clear all caches'
        'ragex.cache.refresh:Refresh embeddings cache'
        'ragex.cache.stats:Display cache statistics'
        'ragex.embeddings.migrate:Migrate embedding models'
        'ragex.ai.usage.stats:Display AI usage statistics'
        'ragex.ai.cache.stats:Display AI cache statistics'
        'ragex.ai.cache.clear:Clear AI response cache'
        'ragex.refactor:Interactive refactoring wizard'
        'ragex.configure:Interactive configuration wizard'
        'ragex.dashboard:Live monitoring dashboard'
    )
    _describe 'ragex tasks' tasks
}

_ragex_embedding_models() {
    local -a models
    models=(
        'all_minilm_l6_v2:Sentence-BERT (384 dims, fast)'
        'all_mpnet_base_v2:MPNet (768 dims, high quality)'
        'codebert_base:CodeBERT (768 dims, code-specific)'
        'paraphrase_multilingual:Multilingual (384 dims)'
    )
    _describe 'embedding models' models
}

_ragex_refactor_operations() {
    local -a operations
    operations=(
        'rename_function:Rename a function'
        'rename_module:Rename a module'
        'change_signature:Modify function signature'
        'extract_function:Extract code into new function'
        'inline_function:Inline function body'
    )
    _describe 'refactoring operations' operations
}

_ragex_ai_providers() {
    local -a providers
    providers=(
        'openai:OpenAI (GPT-4, GPT-3.5)'
        'anthropic:Anthropic (Claude)'
        'deepseek:DeepSeek (DeepSeek-Coder)'
        'deepseek_r1:DeepSeek R1 (Reasoning)'
        'ollama:Ollama (Local Models)'
    )
    _describe 'AI providers' providers
}

_ragex() {
    local context state line
    typeset -A opt_args

    local task="${words[2]}"

    case "$task" in
        ragex.cache.refresh)
            _arguments \
                '(-p --path)'{-p,--path}'[Path to analyze]:directory:_directories' \
                '(-f --force)'{-f,--force}'[Force refresh]' \
                '(-h --help)'{-h,--help}'[Show help]'
            ;;
        ragex.embeddings.migrate)
            _arguments \
                '(-c --check)'{-c,--check}'[Check status]' \
                '(-m --model)'{-m,--model}'[Model to migrate to]:model:_ragex_embedding_models' \
                '(-f --force)'{-f,--force}'[Force migration]' \
                '--clear[Clear embeddings]' \
                '(-h --help)'{-h,--help}'[Show help]'
            ;;
        ragex.refactor)
            _arguments \
                '(-o --operation)'{-o,--operation}'[Refactoring operation]:operation:_ragex_refactor_operations' \
                '(-m --module)'{-m,--module}'[Module name]:module:' \
                '(-f --function)'{-f,--function}'[Function name]:function:' \
                '(-a --arity)'{-a,--arity}'[Function arity]:arity:(0 1 2 3 4 5)' \
                '(-n --new-name)'{-n,--new-name}'[New name]:name:' \
                '(-h --help)'{-h,--help}'[Show help]'
            ;;
        ragex.configure)
            _arguments \
                '(-s --show)'{-s,--show}'[Show current configuration]' \
                '(-h --help)'{-h,--help}'[Show help]'
            ;;
        ragex.dashboard)
            _arguments \
                '(-i --interval)'{-i,--interval}'[Refresh interval (ms)]:interval:(500 1000 2000 5000)' \
                '(-h --help)'{-h,--help}'[Show help]'
            ;;
        ragex.ai.usage.stats)
            _arguments \
                '--provider[Filter by provider]:provider:_ragex_ai_providers' \
                '(-h --help)'{-h,--help}'[Show help]'
            ;;
        ragex.ai.cache.clear)
            _arguments \
                '--operation[Clear specific operation]:operation:(query explain analyze summarize)' \
                '(-h --help)'{-h,--help}'[Show help]'
            ;;
        ragex.cache.clear|ragex.cache.stats|ragex.ai.cache.stats)
            _arguments \
                '(-h --help)'{-h,--help}'[Show help]'
            ;;
        *)
            # Complete task names
            _ragex_tasks
            ;;
    esac
}

# Only provide completions if current word starts with "ragex."
if [[ "${words[2]}" == ragex.* ]] || [[ "${words[CURRENT]}" == ragex.* ]]; then
    _ragex "$@"
fi
