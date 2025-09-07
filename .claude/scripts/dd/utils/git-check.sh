#!/bin/bash

# Git 状态检查工具
# 提供安全的 Git 状态检查和问题识别功能

# 检查未提交文件
check_uncommitted_files() {
  echo "🔍 检查未提交文件..."
  
  local uncommitted_count=$(git status --porcelain 2>/dev/null | wc -l)
  
  if [ "$uncommitted_count" -eq 0 ]; then
    echo "✅ 工作区干净, 没有未提交文件"
    return 0
  else
    echo "❌ 发现 $uncommitted_count 个未提交的文件变更: "
    echo ""
    git status --porcelain 2>/dev/null | head -20
    echo ""
    echo "⚠️ 建议处理方式: "
    echo "  git add <文件名>     # 添加需要提交的文件"
    echo "  git commit -m '...'  # 提交变更"
    echo "  git stash           # 暂存工作区变更"
    echo "  git checkout -- <文件名> # 丢弃特定文件的变更"
    echo ""
    return 1
  fi
}

# 检查远程仓库更新
check_remote_updates() {
  echo "🔍 检查远程仓库更新..."
  
  # 安全地执行 git fetch
  if git fetch origin 2>/dev/null; then
    echo "✅ 成功获取远程仓库信息"
  else
    echo "⚠️ 无法连接远程仓库, 跳过远程检查"
    return 0
  fi
  
  # 检查是否落后于远程分支
  local current_branch=$(git branch --show-current 2>/dev/null)
  if [ -z "$current_branch" ]; then
    echo "⚠️ 无法确定当前分支, 跳过远程比较"
    return 0
  fi
  
  local behind_count=$(git rev-list --count HEAD..origin/$current_branch 2>/dev/null || echo "0")
  local ahead_count=$(git rev-list --count origin/$current_branch..HEAD 2>/dev/null || echo "0")
  
  if [ "$behind_count" -eq 0 ] && [ "$ahead_count" -eq 0 ]; then
    echo "✅ 本地分支与远程分支同步"
    return 0
  elif [ "$behind_count" -gt 0 ]; then
    echo "❌ 本地分支落后远程 $behind_count 个提交: "
    echo ""
    git log --oneline HEAD..origin/$current_branch 2>/dev/null | head -10
    echo ""
    echo "🔧 建议处理方式: "
    echo "  git pull origin $current_branch  # 拉取并合并远程变更"
    echo "  git rebase origin/$current_branch # 变基到远程分支"
    echo ""
    return 1
  elif [ "$ahead_count" -gt 0 ]; then
    echo "⚠️ 本地分支领先远程 $ahead_count 个提交"
    echo "💡 建议在合适时机推送到远程: git push origin $current_branch"
    return 0
  fi
}

# 检查分支状态
check_branch_status() {
  echo "🔍 检查分支状态..."
  
  local current_branch=$(git branch --show-current 2>/dev/null)
  if [ -z "$current_branch" ]; then
    echo "❌ 无法确定当前分支"
    return 1
  fi
  
  echo "✅ 当前分支: $current_branch"
  
  # 检查是否在主分支上直接开发
  if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
    echo "⚠️ 正在主分支上工作, 建议使用功能分支: "
    echo "  git checkout -b feature/功能名称  # 创建功能分支"
    echo "  git checkout -b fix/问题描述     # 创建修复分支"
  fi
  
  return 0
}

# 检查合并冲突
check_merge_conflicts() {
  echo "🔍 检查合并冲突..."
  
  # 检查是否存在合并冲突标记
  local conflict_files=$(git diff --name-only --diff-filter=U 2>/dev/null)
  
  if [ -z "$conflict_files" ]; then
    echo "✅ 没有检测到合并冲突"
    return 0
  else
    echo "❌ 检测到合并冲突文件: "
    echo "$conflict_files"
    echo ""
    echo "🔧 冲突解决步骤: "
    echo "  1. 编辑冲突文件, 解决 <<<<<<<, =======, >>>>>>> 标记"
    echo "  2. git add <解决的文件>  # 标记冲突已解决"
    echo "  3. git commit           # 完成合并提交"
    echo ""
    return 1
  fi
}

# 检查代码状态与功能状态一致性
check_code_feature_consistency() {
  local feature_name="$1"
  
  if [ -z "$feature_name" ]; then
    echo "🔍 跳过代码状态一致性检查（未指定功能）"
    return 0
  fi
  
  echo "🔍 检查代码状态与功能状态一致性..."
  
  local current_branch=$(git branch --show-current 2>/dev/null)
  local expected_branch="feature/$feature_name"
  
  if [ "$current_branch" != "$expected_branch" ]; then
    echo "⚠️ 分支不匹配: "
    echo "  当前分支: $current_branch"
    echo "  期望分支: $expected_branch"
    echo ""
    echo "💡 建议: "
    echo "  git checkout -b $expected_branch  # 创建功能分支"
    echo "  git checkout $expected_branch     # 切换到功能分支"
  else
    echo "✅ 分支与功能匹配"
  fi
  
  return 0
}

# 生成 Git 状态报告
generate_git_status_report() {
  local feature_name="$1"
  
  echo "📊 Git 状态检查报告"
  echo "===================="
  echo "检查时间: $(date)"
  echo "当前分支: $(git branch --show-current 2>/dev/null || echo '未知')"
  echo "功能名称: ${feature_name:-'未指定'}"
  echo ""
  
  local all_good=true
  
  if ! check_uncommitted_files; then
    all_good=false
  fi
  echo ""
  
  if ! check_remote_updates; then
    all_good=false
  fi
  echo ""
  
  check_branch_status
  echo ""
  
  if ! check_merge_conflicts; then
    all_good=false
  fi
  echo ""
  
  check_code_feature_consistency "$feature_name"
  echo ""
  
  if [ "$all_good" = true ]; then
    echo "🎉 Git 状态检查通过, 可以安全开始开发"
    return 0
  else
    echo "⚠️ 发现需要处理的 Git 问题, 建议先解决后再继续"
    return 1
  fi
}

# 主函数
main() {
  local command="$1"
  local feature_name="$2"
  
  case "$command" in
    "full-check")
      generate_git_status_report "$feature_name"
      ;;
    "uncommitted")
      check_uncommitted_files
      ;;
    "remote")
      check_remote_updates
      ;;
    "branch")
      check_branch_status
      ;;
    "conflicts")
      check_merge_conflicts
      ;;
    "consistency")
      check_code_feature_consistency "$feature_name"
      ;;
    *)
      echo "用法: $0 {full-check|uncommitted|remote|branch|conflicts|consistency} [feature_name]"
      echo ""
      echo "命令说明: "
      echo "  full-check    - 完整的 Git 状态检查"
      echo "  uncommitted   - 检查未提交文件"
      echo "  remote        - 检查远程仓库更新"
      echo "  branch        - 检查分支状态"
      echo "  conflicts     - 检查合并冲突"
      echo "  consistency   - 检查代码状态一致性"
      exit 1
      ;;
  esac
}

# 如果脚本被直接调用
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
  main "$@"
fi