import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

import release_wave as mod


def row(short: str, version: str, aggregate: str = '-', changelog: bool = True) -> dict:
    return {
        'name': f'w_tools_{short}',
        'short': short,
        'path': f'packages/{short}',
        'aggregate': aggregate,
        'version': version,
        'changelog': changelog,
    }


def data(
    rows,
    *,
    published=None,
    not_found=(),
    unreachable=(),
    drift=None,
    snapshots=None,
    pending=(),
    pending_snapshots=False,
    root_version='12.0.2',
    root_published='12.0.1',
    root_changelog_ok=True,
    dirty=False,
    branch='main',
    head='abc',
    origin_main='abc',
    check_errors=(),
    release_errors=(),
    audit_drift=True,
) -> mod.PlanData:
    return mod.PlanData(
        rows=list(rows),
        published=dict(published or {}),
        not_found=set(not_found),
        unreachable=set(unreachable),
        drift=dict(drift or {}),
        snapshots=dict(snapshots or {}),
        pending=set(pending),
        pending_snapshots=pending_snapshots,
        root_version=root_version,
        root_published=root_published,
        root_not_found=False,
        root_unreachable=False,
        root_changelog_ok=root_changelog_ok,
        changelog={item['short']: bool(item['changelog']) for item in rows},
        git={
            'dirty': dirty,
            'branch': branch,
            'head': head,
            'origin_main': origin_main,
            'ahead': 0,
            'behind': 0,
        },
        check_errors=list(check_errors),
        release_errors=list(release_errors),
        audit_drift=audit_drift,
    )


class ClassifyTest(unittest.TestCase):
    def test_local_ahead_is_publish(self):
        self.assertEqual(mod.classify('2.1.1', '2.1.0', pending=False, unreachable=False, not_found=False)[0], 'publish')

    def test_equal_is_skip(self):
        self.assertEqual(mod.classify('2.1.0', '2.1.0', pending=False, unreachable=False, not_found=False)[0], 'skip')

    def test_behind_is_blocked(self):
        self.assertEqual(mod.classify('2.0.0', '2.1.0', pending=False, unreachable=False, not_found=False)[0], 'blocked')

    def test_pending_first_release_is_publish(self):
        action, _ = mod.classify('1.0.0', None, pending=True, unreachable=False, not_found=True)
        self.assertEqual(action, 'publish')

    def test_unknown_404_is_blocked(self):
        action, _ = mod.classify('1.0.0', None, pending=False, unreachable=False, not_found=True)
        self.assertEqual(action, 'blocked')

    def test_unreachable_pubdev_is_blocked(self):
        action, _ = mod.classify('1.0.0', None, pending=False, unreachable=True, not_found=False)
        self.assertEqual(action, 'blocked')


class OrderTest(unittest.TestCase):
    def test_contract_before_implementation_and_cli_last(self):
        order, error = mod.order_candidates(
            ['app_getx', 'map_google', 'app', 'map', 'cli'],
            {
                'app_getx': ['app'],
                'map_google': ['map'],
                'cli': ['app_getx', 'map_google'],
            },
        )
        self.assertIsNone(error)
        self.assertLess(order.index('app'), order.index('app_getx'))
        self.assertLess(order.index('map'), order.index('map_google'))
        self.assertEqual(order[-1], 'cli')

    def test_cycle_is_reported(self):
        order, error = mod.order_candidates(['a', 'b'], {'a': ['b'], 'b': ['a']})
        self.assertEqual(order, [])
        self.assertIn('依赖环', error)


class SelectionTest(unittest.TestCase):
    def test_app_getx_pulls_in_app(self):
        rows = [row('app', '3.1.1'), row('app_getx', '2.1.1')]
        selected, include_root = mod._selected_rows(rows, 'app_getx')
        self.assertEqual([item['short'] for item in selected], ['app', 'app_getx'])
        self.assertFalse(include_root)

    def test_root_pulls_in_aggregate_packages(self):
        rows = [
            row('core', '3.1.1', aggregate='root'),
            row('app_getx', '2.1.1'),
        ]
        selected, include_root = mod._selected_rows(rows, 'root')
        self.assertEqual([item['short'] for item in selected], ['core'])
        self.assertTrue(include_root)

    def test_unknown_package_is_rejected(self):
        with self.assertRaises(ValueError):
            mod._selected_rows([row('core', '3.1.1')], 'nope')


class BuildPlanTest(unittest.TestCase):
    def test_typical_wave_order_and_root_blocker(self):
        rows = [
            row('core', '3.1.1', aggregate='root'),
            row('app_getx', '2.1.1'),
            row('map_google', '2.0.1'),
            row('cli', '1.17.1'),
        ]
        plan = mod.build_plan(
            data(
                rows,
                published={'core': '3.1.1', 'app_getx': '2.1.0', 'map_google': '2.0.0', 'cli': '1.17.0'},
                snapshots={'core': '3.1.1', 'app_getx': '2.1.0', 'map_google': '2.0.0', 'cli': '1.17.0'},
            ),
        )
        self.assertEqual(plan['order'], ['app_getx', 'map_google', 'cli'])
        self.assertEqual(plan['summary']['publish'], 3)
        self.assertEqual(plan['root']['action'], 'publish')
        self.assertIn('先发布子包并合入快照 PR', plan['root']['requires'])
        self.assertFalse(any('先发布子包并合入快照 PR' in item for item in plan['blockers']))
        self.assertTrue(plan['snapshots_required'])

    def test_root_snapshot_mismatch_blocks_root(self):
        rows = [
            row('core', '3.1.1', aggregate='root'),
            row('app_getx', '2.1.1'),
        ]
        plan = mod.build_plan(
            data(
                rows,
                published={'core': '3.1.1', 'app_getx': '2.1.0'},
                snapshots={'core': '3.0.0', 'app_getx': '2.1.0'},
            ),
        )
        self.assertTrue(any('core 快照 3.0.0' in item for item in plan['blockers']))

    def test_missing_changelog_blocks_package(self):
        rows = [row('app_getx', '2.1.1', changelog=False)]
        plan = mod.build_plan(
            data(rows, published={'app_getx': '2.1.0'}, snapshots={'app_getx': '2.1.0'}),
        )
        package = next(p for p in plan['packages'] if p['short'] == 'app_getx')
        self.assertEqual(package['action'], 'blocked')
        self.assertIn('CHANGELOG', package['reason'])

    def test_dirty_worktree_is_a_blocker(self):
        rows = [row('app_getx', '2.1.1')]
        plan = mod.build_plan(
            data(rows, published={'app_getx': '2.1.0'}, snapshots={'app_getx': '2.1.0'}, dirty=True),
        )
        self.assertTrue(any('工作区有未提交改动' in item for item in plan['blockers']))

    def test_no_drift_audit_adds_one_warning(self):
        rows = [row('app_getx', '2.1.1')]
        plan = mod.build_plan(
            data(rows, published={'app_getx': '2.1.0'}, snapshots={'app_getx': '2.1.0'}, audit_drift=False),
        )
        warnings = [item for item in plan['warnings'] if '未核对 code drift' in item]
        self.assertEqual(len(warnings), 1)

    def test_root_only_plan(self):
        plan = mod.build_plan(data([], published={}, snapshots={}))
        self.assertEqual(plan['order'], [])
        self.assertEqual(plan['root']['action'], 'publish')
        self.assertFalse(plan['snapshots_required'])

    def test_schema(self):
        plan = mod.build_plan(data([], root_version='12.0.2', root_published='12.0.1'))
        self.assertEqual(plan['schema'], 'w_tools.release_plan/1')


if __name__ == '__main__':
    unittest.main()
