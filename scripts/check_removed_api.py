#!/usr/bin/env python3
"""检查已删除的 API 是否仍出现在文档/示例（迁移/历史文档除外）。

推荐路径（root AGENTS.md、docs/agents、docs/recipes、docs/modules、各包 README、
消费方模板、example）里如果出现已删除符号，除非**同一条目**明确写
“已删除 / 已移除 / 不再提供 / 迁移”，否则失败。

“同一条目”不是整行：表格按单元格、正文按就近 40 字判断。
以前只要整行出现“删除”两个字就放行，导致“前半句推荐、后半句提一句删除”也能过。
"""
from __future__ import annotations

import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent
# 已删除的公开名白名单：每次删除 / 废弃都要在这里登记，见 docs/ai-contract.md §7。
names = [
    # figma 0.13.0：弃用别名 / 转发方法 / 同义 flag。
    r'\bUsageSummary\b', r'FigmaSpecRenderer\.renderMarkdown', r'no-markdown',
    r'WRowButtons', r'WRowButtonsController', r'WRow\b', r'WSizeBox', r'WPadding', r'WColumn',
    r'WImageCachePolicy', r'WImageConfig', r'WImageLoadConfig', r'WImageDefaults\b', r'WMapConfig',
    r'WImageDefaultsScope', r'WImageEmptyError',
    r'WImageNetworkError', r'WImageAssetError', r'WImageDecodeError', r'WImageProviderError',
    r'WImageFileError', r'WImageUnsupportedError', r'WImage\.avatar', r'WImage\.thumbnail',
    r'WImage\.cover', r'WImage\.assetImage', r'WImage\.(?:network|asset|file|base64|memory|provider)', r'WToastConfig', r'WFormDefaults',
    r'WFormBorderConfigBuilder', r'WFormRowBorderExtension', r'withFormBorder',
    r'WFormBorderConfigScope', r'WFormBorderState', r'\bWFormBorderConfig\b', r'WFormPopupRoute',
    r'WAsyncViewDefaults', r'WAsyncSliverDefaults', r'WAsyncBuilder', r'WAsyncConfig',
    r'WAsyncLoading', r'WAsyncState\.errorMessage', r'\bWConfig\b', r'\bWRoute\b', r'WRegExpPattern', r'WRegExpPreset',
    r'WTextConfig', r'\bonDataUpdated\b', r'WApp\(\)', r'WMapConfig\.build',
    # app_getx 2.0：全局语言状态与静态路由栈收口。
    r'\bWAppConfig\b', r'WLocaleConfig\.defaultLanguage', r'WLanguage\.languageStream',
    r'WLanguage\.syncFromConfig', r'WRouteStack\.defaultStack', r'WAppOptions\.applyOrientations',
    r'WAppOptions\.darkTheme', r'WAppOptions\.themeMode', r'WAppOptions\.systemUiOverlayStyle',
    # ui 7.0 的改名：旧名不保留，必须登记，否则 README / example 里的旧推荐拦不住。
    r'WHexColor', r'WImageStyleX',
    # ui 11.0：纯别名删除，圆角裁剪直接用 Flutter ClipRRect。
    r'\bWClipRRect\b',
    r'\bWNavBar\.onItemTap\b',
    r'\bnotifyScrollPercentage\b',
    r'\bWTextStyleExtension\b',
    r'\bWUiWidgetExtension\b',
    r'\bWImageError\.data\b',
    r'\bWListViewSliver\.keepAlive\b',
    r'\bWButtonStyles\b',
    r'\bWImageFrame\b',
    r'\bWImageSlots\.(?:placeholder|emptyWidget|errorWidget)\b',
    r'\bWWidgetExtension\.withBottomBarSpaceOf\b',
    r'\bWWidgetExtension\.with(?:Horizontal|Vertical|Left|Right|Top|Bottom)Padding\b',
    # ui 12.0：纯减法（参数镜像 / 死 API / 原生等价糖）。
    r'\bWStepFlow\b',
    r'\bWNavBarStyle\b',
    r'\bWGlobalKeyExtension\b',
    r'\bWNavController\.(?:animateTo|animation|offset|previousIndex|indexIsChanging)\b',
    r'\bWNumLayoutExtension\.(?:heightBox|widthBox|squareBox|horizontalPadding|verticalPadding|borderRadius)\b',
    r'\bWStringExtension\.(?:toInt|toDouble|toNum|trimAll)\b',
    r'\bWBoxDecorationExtension\.(?:withColor|withoutColor|withGradient|withoutGradient|withBorder|withoutBorder|withBorderRadius|withoutBorderRadius|withShadow|withoutShadow|withShape)\b',
    r'preventNotificationPropagation',
    r'hasChildSemanticsWhenDisabled',
    r'\bWImageErrorView\.compact\b',
    r'\bWScaffold\.underlayWidget\b',
    r'\bunderlayWidget\b',
    r'\bWImageStyle\.(?:avatar|thumbnail)\b',
    # ui 12.0 第三批：按钮收口到 Material ButtonStyle。
    r'\bWButtonStyle\b',
    r'\bWButtonStyleSet\b',
    r'\bWButtonMotion\b',
    r'\bWButtonSemantics\b',
    r'\bWButtonContentBuilder\b',
    r'\bWButtonResolvedStyle\b',
    # ui 12.0 第二批：tab 镜像 / 图片状态机 / 全局资源前缀。
    r'\bWTabBar\b',
    r'\bWTabBarStyle\b',
    r'\bWImageController\b',
    r'\bWImageLoadSnapshot\b',
    r'\bWImageSlots\.(?:emptyBuilder|progressBuilder|showRetryButton|retryLabel)\b',
    r'\bWImageSource\.parse\b',
    r'\bWAssets\b',
    r'\bWStringExtension\.assetImagePath\b',
    r'\bWImageStyle\.(?:margin|padding|withoutMargin|withoutPadding)\b',
    r'\bWImage\.controller\b',
    r'prefix: true',
    r'\bWAssetImageSource\.prefix\b',
    # ui 8.0：Config 过渡入口 / 按钮冗余类型 / Builder 收口。
    r'\bWNavBarConfig\b', r'\bWTabBarConfig\b', r'\bWBadgeConfig\b', r'\bWClipRRectConfig\b',
    r'\bWBadge[^\n|]*\btopRight\b',
    r'WImageErrorKind\.empty',
    r'\bWNumExtension\.borderSide\b',
    r'\bWNumExtension\b',
    r'\bWScreen\.(?:w|h|sp)\b',
    r'\bWScreen\.delegate(?:Width|Height|Font)\b',
    r'\bWScreen\.reset\b',
    r'\bWButtonMetrics\b', r'\bWButtonEffectType\b', r'\bWNotificationListenerBuilder\b',
    # form 6.0：实时派生 formEntered / 内部边框登记收口后删除的公开名。
    r'pruneFormEntered', r'removeFormEntered', r'hasBorder', r'errorChannelOf',
    r'registerBorder', r'unregisterBorder', r'removeErrorChannel',
    # form 7.0：controller 边框通道 / 纯静态工厂 / 冗余 copy 收口。
    r'WFormController\.borders', r'WFormController\.updateValue\b', r'WFormController\.handleChange\b',
    r'WFormScope\.formBorderStyle\b',
    r'WFormInputFormatters\(\)', r'WFormInputFormatters\.phone\b',
    r'WFormValidatorSettings\.copy\b', r'\bWFormBorderDecoration\b', r'WFormBorderDecorationExtension',
    # qr 2.0：控制器归调用方、样式收口、结果结构化后移除的公开名。
    r'WQrViewState', r'WQrViewOverlayShape', r'onQRViewCreated', r'noPermissionCallback',
    r'checkedBorderColor', r'showOverlay', r'restartScan', r'scanInvert', r'WQrController\.internal',
    # device 0.3.0：缓存 / 稳定判定的死代码收口。
    # api 6.0：删除空壳数据层 / 契约类型，Config 改名 Settings，指标与日志 API 收口。
    r'\bIApiPath\b', r'\bApiClientId\b', r'\bBaseRepository\b',
    r'\bBaseLocalDataSource\b', r'\bBaseRemoteDataSource\b',
    r'\bWApiBodyKind\b', r'WApiBody\.kind',
    r'\bWApiConfig\b', r'\bWApiMetricsInterceptor\b', r'\bWApiMetric\b',
    r'WTokenInterceptor\.(?:configureRequest|configureResponse|observeError)',
    r'WLogPart\.errorHint',
    r'CalibrationStore\.isFresh\b', r'Stability\.changedAfter\b',
]
# 以 `)` 结尾的条目不能补尾 `\b`：`)` 后面通常不是单词字符，补了就永远匹配不到。
patterns = [
    re.compile(r'\b' + name + ('' if name.endswith(r'\)') else r'\b'))
    for name in names
]
# 已移除的第三方依赖：当前文档不能再把它列为包依赖。
# 迁移 / 历史文档不在 targets 里，所以这里只影响“现在仍然推荐”的文档。
removed_dependencies = [
    r'\bbadges\b',
]
dependency_patterns = [re.compile(pattern) for pattern in removed_dependencies]
removal = re.compile(r'删除|移除|不再提供|不再依赖|迁移|removed', re.IGNORECASE)

targets = []
for sub in ('docs/agents', 'docs/recipes', 'docs/modules', 'docs/guides'):
    targets += sorted((root / sub).glob('*.md'))
targets += [root / 'README.md', root / 'AGENTS.md']
targets += sorted((root / 'packages').glob('*/README.md'))
targets += sorted((root / 'packages').glob('*/AGENTS.md'))
targets += sorted((root / 'packages').glob('*/example/README.md'))
targets += sorted((root / 'packages').glob('*/example/lib/**/*.dart'))
targets += sorted((root / 'packages/cli/templates/agents').rglob('*.md'))
# catalog 是 explain 的事实源；已删除 API 出现在 usage/pitfalls 里会直接教错 AI。
targets += [root / 'packages/cli/catalog/components.yaml']


def marked_as_removed(line: str, start: int) -> bool:
    """true 表示该符号所在单元格 / 所在句子已经写明“已删除”。"""
    if line.lstrip().startswith('|'):
        cell_start = line.rfind('|', 0, start) + 1
        cell_end = line.find('|', start)
        cell = line[cell_start:cell_end if cell_end >= 0 else len(line)]
        return removal.search(cell) is not None
    sentence_start = max(
        (line.rfind(stop, 0, start) for stop in '。；;'),
        default=-1,
    ) + 1
    sentence_end = min(
        (index for index in (line.find(stop, start) for stop in '。；;') if index >= 0),
        default=len(line),
    )
    return removal.search(line, sentence_start, sentence_end + 1) is not None


bad: list[str] = []
for path in targets:
    if not path.is_file():
        continue
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        for pattern in patterns:
            hit = next(
                (match for match in pattern.finditer(line) if not marked_as_removed(line, match.start())),
                None,
            )
            if hit is not None:
                bad.append(f'{path.relative_to(root)}:{number}: {line.strip()[:100]}')
                break
        else:
            for pattern in dependency_patterns:
                hit = next(
                    (match for match in pattern.finditer(line) if not marked_as_removed(line, match.start())),
                    None,
                )
                if hit is not None:
                    bad.append(
                        f'{path.relative_to(root)}:{number}: 仍引用已移除依赖：{line.strip()[:100]}'
                    )
                    break

if bad:
    print('文档/示例仍引用已删除 API 或依赖：', file=sys.stderr)
    for item in bad:
        print(f'  ✗ {item}', file=sys.stderr)
    sys.exit(1)

print(f'✓ 已删除 API / 依赖未被推荐（{len(targets)} 个文件）')
