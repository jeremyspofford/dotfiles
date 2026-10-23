# Native completion only: never execute Workbench transactions to find candidates.
_workbench_checkpoints() {
  local -a ids expl
  local file
  for file in "$checkpoint_root"/checkpoints/*/checkpoint.json(N-.); do
    ids+=("${file:h:t}")
  done
  _wanted checkpoints expl 'checkpoint' compadd -a ids
}

_workbench() {
  local curcontext="$curcontext" state line checkpoint_root word last_option
  local -A opt_args
  local -a subcommands specs
  subcommands=(
    'doctor:Check tools and configuration drift'
    'plan:Preview configuration changes'
    'apply:Apply an exactly reviewed plan with a checkpoint'
    'checkpoint:Save current configuration'
    'checkpoints:List saved checkpoints'
    'rollback:Preview or apply a checkpoint restore'
  )
  _arguments -C -0 \
    '(-h --help)'{-h,--help}'[Show help]' \
    '--destination=[Configuration destination]:directory:_directories' \
    '--state-dir=[Checkpoint state directory]:directory:_directories' \
    '--color=[Diff color mode]:mode:(auto always never)' \
    '1:command:->command' \
    '*::argument:->arguments' && return

  case "$state" in
    command)
      _describe 'command' subcommands
      ;;
    arguments)
      checkpoint_root=${opt_args[--state-dir]:-$HOME/.local/state/workbench}
      checkpoint_root=${(Q)checkpoint_root}
      [[ $checkpoint_root == '~/'* ]] && checkpoint_root=$HOME/${checkpoint_root#\~/}
      specs=('(-h --help)'{-h,--help}'[Show help]')
      case "$words[1]" in
        plan|apply|checkpoint)
          specs+=(
            '--components[Components to manage]:component:(shell git mise tmux nvim workbench herdr zoetrope)'
            '--existing=[How to handle existing files]:policy:(skip replace)'
          )
          # argparse accepts several components, ending at the next option.
          for word in "${words[@]:1:$((CURRENT - 2))}"; do
            [[ $word == --* ]] && last_option=$word
          done
          if [[ $last_option == --components ]]; then
            specs+=('*:component:(shell git mise tmux nvim workbench herdr zoetrope)')
          fi
          case "$words[1]" in
            plan) specs+=('--format=[Preview format]:format:(text html)') ;;
            apply) specs+=('--plan=[Exact hash from the reviewed preview]:reviewed plan hash:'
                           '--interactive[Choose optional tools and updates in a checklist]') ;;
          esac
          ;;
        rollback)
          specs+=(
            '1:checkpoint:_workbench_checkpoints'
            '--plan=[Exact hash from the reviewed rollback preview]:reviewed plan hash:'
            '--replace-edits[Include later edits in preview and restore]'
          )
          ;;
      esac
      _arguments "$specs[@]"
      ;;
  esac
}

compdef _workbench workbench
