import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from check_public_catalog import dont_use_for_error


class DontUseForTest(unittest.TestCase):
    def test_missing(self):
        problem = dont_use_for_error({'name': '`WX`'})
        self.assertIsNotNone(problem)
        self.assertIn('缺', problem)

    def test_placeholder(self):
        for value in ('—', '-', 'N/A', '无', '不适用', '不要用'):
            problem = dont_use_for_error({'name': '`WX`', 'dontUseFor': value})
            self.assertIsNotNone(problem, value)
            self.assertIn('占位符', problem)

    def test_too_short(self):
        problem = dont_use_for_error({'name': '`WX`', 'dontUseFor': '未挂载'})
        self.assertIsNotNone(problem)
        self.assertIn('太短', problem)

    def test_specific_boundary(self):
        self.assertIsNone(
            dont_use_for_error({
                'name': '`WX`',
                'dontUseFor': '未挂载到地图时调用没有任何效果',
            })
        )


if __name__ == '__main__':
    unittest.main()
