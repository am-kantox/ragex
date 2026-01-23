#!/usr/bin/env bash
# Bash completion for Ragex Mix tasks
# Install: copy to /etc/bash_completion.d/ or source in ~/.bashrc

_ragex_completion() {
    local cur prev tasks
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # All ragex Mix tasks
    tasks="
        ragex.cache.clear
        ragex.cache.refresh
        ragex.cache.stats
        ragex.embeddings.migrate
        ragex.ai.usage.stats
        ragex.ai.cache.stats
        ragex.ai.cache.clear
        ragex.refactor
        ragex.configure
        ragex.dashboard
    "

    # Task-specific options
    case "${COMP_WORDS[1]}" in
        ragex.cache.refresh)
            case "$prev" in
                --path|-p)
                    # Complete directory paths
                    COMPREPLY=( $(compgen -d -- "$cur") )
                    return 0
                    ;;
                *)
                    COMPREPLY=( $(compgen -W "--path --force --help" -- "$cur") )
                    return 0
                    ;;
            esac
            ;;
        ragex.embeddings.migrate)
            case "$prev" in
                --model|-m)
                    COMPREPLY=( $(compgen -W "all_minilm_l6_v2 all_mpnet_base_v2 codebert_base paraphrase_multilingual" -- "$cur") )
                    return 0
                    ;;
                *)
                    COMPREPLY=( $(compgen -W "--check --model --force --clear --help" -- "$cur") )
                    return 0
                    ;;
            esac
            ;;
        ragex.refactor)
            case "$prev" in
                --operation|-o)
                    COMPREPLY=( $(compgen -W "rename_function rename_module change_signature extract_function inline_function" -- "$cur") )
                    return 0
                    ;;
                --module|-m|--function|-f|--new-name|-n)
                    # No completion for these
                    return 0
                    ;;
                --arity|-a)
                    COMPREPLY=( $(compgen -W "0 1 2 3 4 5" -- "$cur") )
                    return 0
                    ;;
                *)
                    COMPREPLY=( $(compgen -W "--operation --module --function --arity --new-name --help" -- "$cur") )
                    return 0
                    ;;
            esac
            ;;
        ragex.configure)
            COMPREPLY=( $(compgen -W "--show --help" -- "$cur") )
            return 0
            ;;
        ragex.dashboard)
            case "$prev" in
                --interval|-i)
                    COMPREPLY=( $(compgen -W "500 1000 2000 5000" -- "$cur") )
                    return 0
                    ;;
                *)
                    COMPREPLY=( $(compgen -W "--interval --help" -- "$cur") )
                    return 0
                    ;;
            esac
            ;;
        ragex.ai.usage.stats)
            case "$prev" in
                --provider)
                    COMPREPLY=( $(compgen -W "openai anthropic deepseek deepseek_r1 ollama" -- "$cur") )
                    return 0
                    ;;
                *)
                    COMPREPLY=( $(compgen -W "--provider --help" -- "$cur") )
                    return 0
                    ;;
            esac
            ;;
        ragex.ai.cache.clear)
            case "$prev" in
                --operation)
                    COMPREPLY=( $(compgen -W "query explain analyze summarize" -- "$cur") )
                    return 0
                    ;;
                *)
                    COMPREPLY=( $(compgen -W "--operation --help" -- "$cur") )
                    return 0
                    ;;
            esac
            ;;
        *)
            # Complete Mix task names
            if [[ ${COMP_WORDS[0]} == "mix" ]]; then
                COMPREPLY=( $(compgen -W "$tasks" -- "$cur") )
                return 0
            fi
            ;;
    esac
}

# Register completion for mix command
complete -F _ragex_completion mix
