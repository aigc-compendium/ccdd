#!/bin/bash

# Markdown 文件格式化脚本
# 使用 Prettier 格式化项目中的所有 Markdown 文件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 帮助信息
show_help() {
    echo -e "${BLUE}📝 Markdown 格式化工具${NC}"
    echo "使用 Prettier 格式化项目中的所有 Markdown 文件"
    echo ""
    echo "用法："
    echo "  $0 [选项]"
    echo ""
    echo "选项："
    echo "  -h, --help     显示帮助信息"
    echo "  -c, --check    只检查，不修改文件"
    echo "  -v, --verbose  显示详细信息"
    echo ""
    echo "示例："
    echo "  $0              # 格式化所有 MD 文件"
    echo "  $0 --check      # 只检查不修改"
}

# 默认参数
CHECK_ONLY=false
VERBOSE=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo -e "${RED}错误: 未知参数 $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 日志函数
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "🔍 $1"
    fi
}

# 检查 Prettier 是否可用
check_prettier() {
    if command -v prettier >/dev/null 2>&1; then
        return 0
    elif command -v npx >/dev/null 2>&1 && npx prettier --version >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 获取 Prettier 命令
get_prettier_cmd() {
    if command -v prettier >/dev/null 2>&1; then
        echo "prettier"
    else
        echo "npx prettier"
    fi
}

# 主函数
main() {
    echo -e "${BLUE}🚀 Markdown 格式化工具启动${NC}"
    echo ""
    
    # 检查 Prettier
    if ! check_prettier; then
        log_error "未找到 Prettier！"
        echo ""
        echo "请安装 Prettier："
        echo "  npm install -g prettier              # 全局安装"
        echo "  npm install --save-dev prettier     # 项目安装"
        exit 1
    fi
    
    local prettier_cmd
    prettier_cmd=$(get_prettier_cmd)
    log_info "使用: $prettier_cmd"
    
    if [[ "$CHECK_ONLY" == "true" ]]; then
        log_info "运行模式: 检查模式"
    else
        log_info "运行模式: 格式化模式"
    fi
    echo ""
    
    # 构建命令
    local cmd="$prettier_cmd"
    
    if [[ "$CHECK_ONLY" == "true" ]]; then
        cmd+=" --check"
    else
        cmd+=" --write"
    fi
    
    # 添加文件模式
    cmd+=" '**/*.md'"
    
    # 显示命令（如果开启详细模式）
    if [[ "$VERBOSE" == "true" ]]; then
        log_verbose "执行命令: $cmd"
        echo ""
    fi
    
    # 执行 Prettier
    if eval "$cmd"; then
        if [[ "$CHECK_ONLY" == "true" ]]; then
            log_success "所有 Markdown 文件格式正确！"
        else
            log_success "Markdown 文件格式化完成！"
        fi
    else
        if [[ "$CHECK_ONLY" == "true" ]]; then
            log_error "发现需要格式化的文件，请运行: $0"
            exit 1
        else
            log_error "格式化过程中出现错误"
            exit 1
        fi
    fi
}

# 运行主函数
main "$@"