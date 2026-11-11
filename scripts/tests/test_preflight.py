import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class PreflightRootDryRunTest(unittest.TestCase):
    def test_root_dry_run_failure_counts_as_failure(self):
        """根包 dry-run 失败必须让 --all / --with-dry-run 失败。

        以前它只打印「! 根包 dry-run 失败」，退出码仍是 0；真正的打包回归
        （根包缺物料 / 暂存逻辑坏了）会拖到发布当天才发现。
        """
        text = (ROOT / 'scripts/preflight.sh').read_text()
        self.assertIn('run "publish dry-run root"', text)
        self.assertNotIn('不会让整次门禁失败', text)
        self.assertNotIn('仅在全部子包已上线后才应通过', text)

    def test_failure_summary_lists_failed_steps(self):
        """失败步骤名要在结尾汇总，避免被几百行测试进度冲掉。"""
        text = (ROOT / 'scripts/preflight.sh').read_text()
        self.assertIn('failed_steps', text)
        self.assertIn('门禁失败：${failed_steps[*]}', text)


if __name__ == '__main__':
    unittest.main()
