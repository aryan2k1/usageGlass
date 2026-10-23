import importlib.util, pathlib, tempfile, unittest, json, time, subprocess
spec=importlib.util.spec_from_file_location('backend',pathlib.Path(__file__).parents[1]/'Sources/UsageGlass/Resources/usageglass_backend.py')
b=importlib.util.module_from_spec(spec);spec.loader.exec_module(b)
class BackendTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.old=(b.HOME,b.BASE,b.SETTINGS)
  b.HOME=pathlib.Path(self.tmp.name);b.BASE=b.HOME/'support';b.SETTINGS=b.HOME/'.claude/settings.json'
 def tearDown(self): b.HOME,b.BASE,b.SETTINGS=self.old;self.tmp.cleanup()
 def test_all_quota_buckets_and_unknown(self):
  snap=b.codex_snapshot({'rateLimitsByLimitId':{'codex':{'primary':{'usedPercent':0},'secondary':{'usedPercent':98}},'spark':{'primary':{'usedPercent':25},'individualLimit':{'remainingPercent':40,'used':6,'limit':10}}}},None)
  self.assertEqual(len(snap['windows']),4);self.assertEqual(snap['windows'][0]['usedPercent'],0)
  self.assertIsNone(b.window('five_hour',{})['usedPercent'])
 def test_bridge_allowlist(self):
  data=b.safe_bridge_payload({'prompt':'SECRET','api_key':'SECRET','cwd':'SECRET','context_window':{'current_usage':{'input_tokens':2,'cache_read_input_tokens':3}},'rate_limits':{'future_model':{'used_percentage':42,'secret':'SECRET'}}})
  self.assertNotIn('SECRET',json.dumps(data));self.assertEqual(data['rate_limits']['future_model']['used_percentage'],42)
 def test_install_restore_exact_and_options(self):
  b.SETTINGS.parent.mkdir();raw=b'{\n "other": 1, "statusLine": {"type":"command","command":"echo old","padding":2,"refreshInterval":3000}\n}\n';b.SETTINGS.write_bytes(raw)
  b.install();settings=json.loads(b.SETTINGS.read_bytes());self.assertEqual(settings['statusLine']['padding'],2)
  b.uninstall();self.assertEqual(b.SETTINGS.read_bytes(),raw)
 def test_restore_keeps_later_settings(self):
  b.SETTINGS.parent.mkdir();b.SETTINGS.write_text('{"other":1}')
  b.install();s=json.loads(b.SETTINGS.read_text());s['other']=2;b.SETTINGS.write_text(json.dumps(s))
  b.uninstall();self.assertEqual(json.loads(b.SETTINGS.read_text()),{'other':2})
 def test_restore_rejects_changed_statusline(self):
  b.install();s=json.loads(b.SETTINGS.read_text());s['statusLine']={'command':'new'};b.SETTINGS.write_text(json.dumps(s))
  with self.assertRaises(ValueError): b.uninstall()
  self.assertEqual(json.loads(b.SETTINGS.read_text())['statusLine']['command'],'new')
 def _transcript(self,rows):
  d=b.HOME/'.claude/projects/p';d.mkdir(parents=True);(d/'s.jsonl').write_text('\n'.join(json.dumps(r) for r in rows))
 def test_claude_token_windows_dedupe_and_span(self):
  now=time.time();iso=lambda t:time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime(t))
  row=lambda mid,t,n:{'type':'assistant','requestId':'r'+mid,'timestamp':iso(t),'message':{'id':mid,'model':'m','usage':{'input_tokens':n,'output_tokens':0,'cache_read_input_tokens':999}}}
  self._transcript([row('a',now-60,10),row('a',now-60,10),row('b',now-6*3600,100),row('c',now-9*86400,1000)])
  wins,_=b.claude_token_windows(now);by={w['id']:w['note'] for w in wins}
  self.assertTrue(by['tokens_5h'].startswith('10 tokens'));self.assertTrue(by['tokens_7d'].startswith('110 tokens'))
 def test_claude_snapshot_falls_back_to_tokens_without_bridge(self):
  now=time.time();self._transcript([{'type':'assistant','requestId':'r','timestamp':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime(now)),'message':{'id':'a','model':'m','usage':{'input_tokens':5,'output_tokens':1}}}])
  snap,_=b.claude_snapshot();self.assertEqual(len(snap['windows']),2);self.assertIsNone(snap['windows'][0]['usedPercent']);self.assertIn('connect the bridge',snap['status'])
 def test_claude_snapshot_keeps_last_bridge_reading(self):
  b.atomic(b.BASE/'claude-usage.json',{'capturedAt':time.time()-7200,'session_id':'x','rate_limits':{'five_hour':{'used_percentage':41,'resets_at':time.time()+3600},'seven_day':{'used_percentage':11,'resets_at':time.time()-5}}})
  snap,_=b.claude_snapshot();w={x['id']:x for x in snap['windows']}
  self.assertEqual(w['five_hour']['usedPercent'],41);self.assertIsNone(w['seven_day']['usedPercent'])
 def test_symlink_settings_rejected(self):
  b.SETTINGS.parent.mkdir();target=b.HOME/'target';target.write_text('{}');b.SETTINGS.symlink_to(target)
  with self.assertRaises(ValueError):b.install()
 def test_claude_dedup_and_partial_scope(self):
  p=b.HOME/'.claude/projects/test';p.mkdir(parents=True)
  rows=[None,{'type':'assistant','requestId':'r','message':{'id':'m','model':'a','usage':{'input_tokens':5,'output_tokens':2,'cache_read_input_tokens':3}}}]
  (p/'s.jsonl').write_text('\n'.join(json.dumps(r) for r in rows+rows))
  sessions=b.local_sessions();self.assertEqual(len(sessions),1);self.assertEqual(sessions[0]['inputTokens'],5);self.assertIn('may span models',sessions[0]['scope'])
 def test_tail_bounds(self):
  p=b.HOME/'large';p.write_bytes(b'x'*(b.MAX_BYTES+10)+b'\n{"type":"ok"}\n')
  rows,truncated=b.read_tail(p);self.assertTrue(truncated);self.assertEqual(rows,[{'type':'ok'}])
 def test_null_legacy_does_not_overwrite_bucket(self):
  s=b.codex_snapshot({'rateLimitsByLimitId':{'codex':{'primary':{'usedPercent':42}}},'rateLimits':{'limitId':None,'primary':{'usedPercent':17}}},None)
  self.assertEqual(s['windows'][0]['usedPercent'],42)
 def test_malformed_bridge_shapes(self):
  for data in [None,[],{'context_window':[1],'rate_limits':[2],'model':3},{'context_window':{'current_usage':[1]}}]:
   result=b.safe_bridge_payload(data);self.assertEqual(result['rate_limits'],{})
 def test_previous_command_deadline_and_output_cap(self):
  script=str(pathlib.Path(b.__file__).resolve())
  prefix='import importlib.util;s=importlib.util.spec_from_file_location("b",'+repr(script)+');b=importlib.util.module_from_spec(s);s.loader.exec_module(b);'
  for command in ['sleep 30 & wait','/usr/bin/yes flood']:
   start=time.monotonic()
   result=subprocess.run(['/usr/bin/python3','-c',prefix+'b.run_previous('+repr(command)+',b"{}")'],stdout=subprocess.PIPE,timeout=5)
   self.assertLess(time.monotonic()-start,4);self.assertLessEqual(len(result.stdout),65536)
 def test_human_labels_and_units(self):
  self.assertEqual(b.formatted('spendControlReached',False),'No')
  self.assertEqual(b.formatted('lifetimeTokens',1234567),'1,234,567')
  self.assertEqual(b.formatted('longestRunningTurnSec',3839),'1h 3m 59s')
  self.assertEqual(b.formatted('estimatedUsageUsdMicros',1000000),'$1.0000 USD')
  self.assertEqual(b.formatted('estimatedUsageCreditsMicros',2500000),'2,500,000 microcredits')
  self.assertIn('7-day',b.window('primary',{'windowDurationMins':10080},'codex:')['label'])
  self.assertIn('5-hour',b.window('five_hour',{})['label'])
 def test_synthetic_zero_filtered_real_usage_retained(self):
  p=b.HOME/'.claude/projects/test';p.mkdir(parents=True)
  def row(mid,model,count): return {'type':'assistant','message':{'id':mid,'model':model,'usage':{'input_tokens':count,'output_tokens':0}}}
  (p/'zero.jsonl').write_text(json.dumps(row('1','<synthetic>',0)))
  (p/'real.jsonl').write_text(json.dumps(row('2','claude-real',5)))
  sessions=b.local_sessions();self.assertEqual(len(sessions),1);self.assertEqual(sessions[0]['model'],'claude-real')
if __name__=='__main__':unittest.main()
