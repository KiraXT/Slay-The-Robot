#!/usr/bin/env python3
"""
统一游戏配置转换器 for Slay the Robot
自动检测Excel输入，转换为JSON格式
支持: 卡牌(Cards)、遗物(Artifacts)、事件(Events)

使用方式:
  python convert.py                    # 转换所有配置
  python convert.py --cards            # 仅转换卡牌
  python convert.py --artifacts        # 仅转换遗物
  python convert.py --events           # 仅转换事件
  python convert.py --create-sample    # 创建所有示例文件
  python convert.py --validate-only    # 仅验证不生成
"""

import sys
import argparse
from pathlib import Path
from typing import List, Dict, Callable, Tuple

# 配置路径
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent

# 转换器配置
CONVERTERS = {
    'cards': {
        'name': '卡牌',
        'excel_file': PROJECT_ROOT / "external/config/cards.xlsx",
        'csv_file': PROJECT_ROOT / "external/config/cards.csv",
        'output_dir': PROJECT_ROOT / "external/data/cards",
        'excel_module': 'excel_to_json',
        'converter_class': 'CardConverter',
        'create_sample_func': 'create_sample_excel',
    },
    'artifacts': {
        'name': '遗物',
        'excel_file': PROJECT_ROOT / "external/config/artifacts.xlsx",
        'output_dir': PROJECT_ROOT / "external/data/artifacts",
        'excel_module': 'excel_to_json_artifacts',
        'converter_class': 'ArtifactConverter',
        'create_sample_func': 'create_sample_excel',
    },
    'events': {
        'name': '事件',
        'excel_file': PROJECT_ROOT / "external/config/events.xlsx",
        'output_dir': PROJECT_ROOT / "external/data/events",
        'excel_module': 'excel_to_json_events',
        'converter_class': 'EventConverter',
        'create_sample_func': 'create_sample_excel',
    },
}


def check_excel_support() -> bool:
    """检查是否支持Excel处理"""
    try:
        import pandas as pd
        import openpyxl
        return True
    except ImportError:
        return False


def detect_input_file(converter_type: str) -> Tuple[str, Path]:
    """检测输入文件类型，优先级: Excel > CSV"""
    config = CONVERTERS[converter_type]

    if config['excel_file'].exists():
        return 'excel', config['excel_file']
    elif 'csv_file' in config and config['csv_file'].exists():
        return 'csv', config['csv_file']
    else:
        return None, None


def run_converter(converter_type: str, validate_only: bool = False) -> Tuple[bool, int, int, int]:
    """
    运行指定类型的转换器
    返回: (是否成功, 成功数量, 跳过数量, 错误数量)
    """
    config = CONVERTERS[converter_type]
    file_type, file_path = detect_input_file(converter_type)

    if file_type is None:
        print(f"\n[{config['name']}] 警告: 未找到输入文件")
        print(f"  期望位置: {config['excel_file']}")
        if 'csv_file' in config:
            print(f"  或: {config['csv_file']}")
        return False, 0, 0, 0

    print(f"\n{'='*60}")
    print(f"开始转换 {config['name']}...")
    print(f"文件: {file_path}")
    print('='*60)

    if file_type == 'excel':
        if not check_excel_support():
            print(f"错误: 检测到Excel文件，但缺少pandas/openpyxl依赖")
            return False, 0, 0, 1

        # 动态导入并运行Excel转换器
        module = __import__(config['excel_module'])
        converter_class = getattr(module, config['converter_class'])
        converter = converter_class()
        success, errors = converter.convert()

        # 统计结果
        error_count = len([e for e in errors if getattr(e, 'severity', 'ERROR') == 'ERROR'])
        return error_count == 0 and success, 0, 0, error_count

    else:  # CSV模式 (仅卡牌支持)
        from csv_to_json import CardConverter
        converter = CardConverter()
        success, errors = converter.convert()

        error_count = len([e for e in errors if e.get('severity') == 'ERROR'])
        return error_count == 0 and success, 0, 0, error_count


def create_sample_files(specific_type: str = None):
    """创建示例文件"""
    excel_available = check_excel_support()

    if not excel_available:
        print("Excel支持未安装，创建CSV示例文件...")
        print("提示: 如需Excel支持，请运行: pip install pandas openpyxl")
        # 仅创建卡牌CSV示例
        from csv_to_json import create_sample_csv
        create_sample_csv()
        return

    types_to_create = [specific_type] if specific_type else list(CONVERTERS.keys())

    for conv_type in types_to_create:
        if conv_type not in CONVERTERS:
            continue

        config = CONVERTERS[conv_type]
        print(f"\n创建 {config['name']} 示例文件...")

        try:
            module = __import__(config['excel_module'])
            create_func = getattr(module, config['create_sample_func'])
            create_func()
        except Exception as e:
            print(f"  错误: {e}")


def print_header():
    """打印头部信息"""
    print("=" * 60)
    print("Slay the Robot - 游戏配置转换器")
    print("支持: 卡牌 | 遗物 | 事件")
    print("=" * 60)


def print_summary(results: Dict[str, Dict]):
    """打印转换摘要"""
    print("\n" + "=" * 60)
    print("总体转换摘要")
    print("=" * 60)

    total_success = 0
    total_errors = 0

    for conv_type, result in results.items():
        config = CONVERTERS[conv_type]
        status = "成功" if result['success'] else "失败"
        print(f"\n{config['name']}: {status}")
        if result.get('skipped', 0) > 0:
            print(f"  - 跳过说明行: {result['skipped']}")
        if result.get('errors', 0) > 0:
            print(f"  - 错误数: {result['errors']}")
            total_errors += result['errors']
        if result['success']:
            total_success += 1

    print("\n" + "-" * 60)
    print(f"总计: {total_success}/{len(results)} 类型转换成功")
    if total_errors > 0:
        print(f"      共 {total_errors} 个错误")
    print("=" * 60)


def main():
    """主入口"""
    parser = argparse.ArgumentParser(
        description='Slay the Robot - 统一游戏配置转换器 (Excel/CSV to JSON)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python convert.py                    # 转换所有配置
  python convert.py --cards            # 仅转换卡牌
  python convert.py --artifacts        # 仅转换遗物
  python convert.py --events           # 仅转换事件
  python convert.py --create-sample    # 创建所有示例文件
  python convert.py --create-sample --artifacts  # 仅创建遗物示例
        """
    )

    # 转换类型选项
    parser.add_argument('--cards', action='store_true',
                       help='仅转换卡牌配置')
    parser.add_argument('--artifacts', action='store_true',
                       help='仅转换遗物配置')
    parser.add_argument('--events', action='store_true',
                       help='仅转换事件配置')

    # 其他选项
    parser.add_argument('--create-sample', action='store_true',
                       help='创建示例配置文件')
    parser.add_argument('--validate-only', action='store_true',
                       help='仅验证数据，不生成JSON文件')

    args = parser.parse_args()
    print_header()

    # 确定要转换的类型
    if args.cards:
        types_to_convert = ['cards']
    elif args.artifacts:
        types_to_convert = ['artifacts']
    elif args.events:
        types_to_convert = ['events']
    else:
        # 默认转换所有类型
        types_to_convert = list(CONVERTERS.keys())

    # 创建示例文件
    if args.create_sample:
        if args.cards:
            create_sample_files('cards')
        elif args.artifacts:
            create_sample_files('artifacts')
        elif args.events:
            create_sample_files('events')
        else:
            create_sample_files()
        return 0

    # 运行转换
    results = {}
    for conv_type in types_to_convert:
        try:
            success, success_count, skipped, errors = run_converter(
                conv_type, validate_only=args.validate_only
            )
            results[conv_type] = {
                'success': success,
                'success_count': success_count,
                'skipped': skipped,
                'errors': errors
            }
        except Exception as e:
            print(f"\n[{conv_type}] 转换失败: {e}")
            import traceback
            traceback.print_exc()
            results[conv_type] = {
                'success': False,
                'success_count': 0,
                'skipped': 0,
                'errors': 1
            }

    # 打印摘要
    print_summary(results)

    # 返回退出码
    all_success = all(r['success'] for r in results.values())
    return 0 if all_success else 1


if __name__ == "__main__":
    sys.exit(main())
