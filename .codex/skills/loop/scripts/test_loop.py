import argparse
import importlib.util
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('loop', Path(__file__).with_name('loop.py'))
loop = importlib.util.module_from_spec(spec)
spec.loader.exec_module(loop)


class LoopTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.state = patch.object(loop, 'STATE_DIR', self.root / 'jobs')
        self.state.start()
        self.addCleanup(self.state.stop)
        self.queue = self.root / 'queue.txt'
        self.codex = self.root / 'codex'
        self.codex.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > ' + str(self.queue) + '\n')
        self.codex.chmod(0o700)

    def start(self):
        with patch.dict(loop.os.environ, {'CODEX_THREAD_ID': '00000000-0000-0000-0000-000000000002'}), patch.object(loop.shutil, 'which', return_value=str(self.codex)), patch.object(loop, 'check_queue'), patch.object(loop, 'start_timer') as timer, patch.object(loop, 'print_job') as output:
            loop.command_start(argparse.Namespace(seconds=1, mode='fixed', prompt='greet once'))
            timer.assert_not_called()
            return output.call_args.args[0]

    def test_start_is_ready_for_immediate_execution(self):
        job = self.start()
        self.assertEqual(job['status'], 'running')
        self.assertIsNone(job['next_at'])

    def test_timer_queue_claim_and_completion(self):
        job = self.start()
        with patch.object(loop, 'start_timer'), patch.object(loop, 'print_job'):
            loop.command_next(argparse.Namespace(job_id=job['id'], generation=1, seconds=None))
        loop.command_fire(argparse.Namespace(job_id=job['id'], generation=2, seconds=0))
        self.assertIn('$loop resume ' + job['id'] + ' 2', self.queue.read_text())
        with patch.object(loop, 'print_job'):
            loop.command_claim(argparse.Namespace(job_id=job['id'], generation=2))
            loop.command_stop(argparse.Namespace(job_id=job['id'], reason='completed'))
        self.assertEqual(loop.read_job(job['id'])['status'], 'completed')

    def test_cancel_queued_and_expired_ticks_cannot_run(self):
        for status in ['canceled', 'queued']:
            job = self.start()
            job.update(status=status, expires_at=time.time() - 1)
            loop.save_job(job)
            with self.assertRaises(SystemExit):
                loop.command_claim(argparse.Namespace(job_id=job['id'], generation=1))
        self.assertEqual(loop.read_job(job['id'])['status'], 'expired')

    def test_detached_timer_delivers(self):
        job = self.start()
        job.update(status='scheduled')
        loop.save_job(job)
        with patch.dict(loop.os.environ, {'CODEX_LOOP_STATE_DIR': str(loop.STATE_DIR)}):
            loop.start_timer(job, 1)
        deadline = time.monotonic() + 60
        while not self.queue.exists() and time.monotonic() < deadline:
            time.sleep(0.1)
        self.assertTrue(self.queue.exists())
        self.assertEqual(loop.read_job(job['id'])['status'], 'queued')

    def test_stale_timer_does_not_queue(self):
        job = self.start()
        job.update(status='scheduled', generation=2)
        loop.save_job(job)
        loop.command_fire(argparse.Namespace(job_id=job['id'], generation=1, seconds=0))
        self.assertFalse(self.queue.exists())


if __name__ == '__main__':
    unittest.main()
