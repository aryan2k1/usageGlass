#!/usr/bin/python3
"""Usage Glass: allowlisted metadata only; no network, credential or prompt access."""
import datetime, json, math, os, pathlib, selectors, shutil, signal, re, subprocess, sys, tempfile, time
HOME = pathlib.Path.home()
BASE = HOME / 'Library/Application Support/UsageGlass'
SETTINGS = HOME / '.claude/settings.json'
MAX_BYTES = 2 * 1024 * 1024

def number(value):
    if isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value) and value >= 0:
        return min(value, 2**53)
    return None

def atomic(path, obj, raw=False):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    if path.is_symlink() or path.parent.is_symlink(): raise ValueError('symlink')
    fd, tmp = tempfile.mkstemp(dir=path.parent)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, 'wb') as f: f.write(obj if raw else json.dumps(obj).encode())
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp): os.unlink(tmp)

def read_json(path):
    if path.is_symlink() or path.stat().st_size > MAX_BYTES: raise ValueError('unsafe file')
    return json.loads(path.read_bytes())

def timestamp(s):
    if number(s) is not None: return float(s)
    try: return datetime.datetime.fromisoformat(s.replace('Z','+00:00')).timestamp()
    except (ValueError, TypeError, AttributeError): return None

def label(key):
    special={'planType':'Plan','normalModelSlug':'Standard model','spendControlReached':'Spend control reached','rateLimitReachedType':'Limit reached','longestRunningTurnSec':'Longest running turn','estimatedUsageCreditsMicros':'Estimated usage','estimatedUsageUsdMicros':'Estimated cost','total_cost_usd':'Session cost','total_duration_ms':'Session duration','total_api_duration_ms':'API duration','used_usd':'Spend used','limit_usd':'Spend limit'}
    return special.get(key,re.sub(r'(?<=[a-z0-9])(?=[A-Z])',' ',key).replace('_',' ').capitalize())

def formatted(key, value):
    if isinstance(value,bool): return 'Yes' if value else 'No'
    if value is None: return 'Unavailable'
    n=number(value)
    if n is None: return str(value)
    if key=='estimatedUsageUsdMicros': return f'${n/1000000:,.4f} USD'
    if key=='estimatedUsageCreditsMicros': return f'{n:,.0f} microcredits'
    if key.endswith('_usd'): return f'${n:,.4f} USD'
    if key=='longestRunningTurnSec' or key.endswith('_ms'):
        seconds=n/1000 if key.endswith('_ms') else n
        return f'{int(seconds//3600):,}h {int(seconds%3600//60)}m {int(seconds%60)}s' if seconds>=3600 else f'{int(seconds//60)}m {int(seconds%60)}s'
    if key.endswith('Days'): return f'{n:,.0f} days'
    if key=='hit_ratio': return f'{n*100:.1f}%'
    return f'{n:,.0f}' if float(n).is_integer() else f'{n:,.2f}'

def window(key, value, prefix=''):
    if not isinstance(value, dict): return None
    pct = number(value.get('usedPercent', value.get('used_percentage')))
    mins = number(value.get('windowDurationMins')) or {'five_hour':300,'seven_day':10080}.get(key)
    duration=(f'{mins/1440:g}-day' if mins and mins%1440==0 else f'{mins/60:g}-hour' if mins and mins%60==0 else f'{mins:g}-minute' if mins else None)
    name=(duration+' · '+label(key) if duration and key in ('primary','secondary') else duration or label(key))
    return {'id':prefix+key, 'label':prefix.replace(':',' · ').capitalize() + name, 'usedPercent':pct, 'resetsAt':timestamp(value.get('resetsAt',value.get('resets_at'))), 'windowMinutes':mins}

def codex_response():
    candidates = ['/Applications/ChatGPT.app/Contents/Resources/codex','/Applications/Codex.app/Contents/Resources/codex',str(HOME/'.local/bin/codex'),'/opt/homebrew/bin/codex','/usr/local/bin/codex',shutil.which('codex')]
    cli = next((p for p in candidates if p and os.path.isfile(p) and os.access(p,os.X_OK)),None)
    if not cli: raise RuntimeError('Codex CLI unavailable')
    p = subprocess.Popen([cli,'app-server'],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,start_new_session=True)
    answers, buffer, total = {}, b'', 0
    sel = selectors.DefaultSelector()
    signal.signal(signal.SIGTERM,lambda *a: (_ for _ in ()).throw(SystemExit(1)))  # run cleanup if the app kills us
    try:
        sel.register(p.stdout,selectors.EVENT_READ)
        for req in [{'id':1,'method':'initialize','params':{'clientInfo':{'name':'usageglass','version':'0.1.0'}}},{'method':'initialized','params':{}},{'id':2,'method':'account/rateLimits/read','params':None},{'id':3,'method':'account/usage/read','params':{}}]:
            p.stdin.write(json.dumps(req).encode()+b'\n'); p.stdin.flush()
        expected=2
        today=HOME/'.codex/sessions'/datetime.date.today().strftime('%Y/%m/%d')
        recent=recent_files(today,1)
        if recent:
            match=re.search(r'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$',recent[0][1].stem)
            if match:
                req={'id':4,'method':'account/usage/read','params':{'threadId':match.group(1)}}
                p.stdin.write(json.dumps(req).encode()+b'\n');p.stdin.flush();expected=3
        end = time.monotonic()+12
        while time.monotonic()<end and len(answers)<expected:
            if not sel.select(0.2): continue
            chunk=os.read(p.stdout.fileno(),65536)
            if not chunk: break
            total+=len(chunk)
            if total>MAX_BYTES: break
            buffer+=chunk
            while b'\n' in buffer:
                line,buffer=buffer.split(b'\n',1)
                try:
                    event=json.loads(line)
                    if event.get('id') in (2,3,4): answers[event['id']]=event.get('result')
                except (ValueError,AttributeError): pass
        return answers
    finally:
        sel.close()
        for sig in (signal.SIGTERM,signal.SIGKILL):
            try: os.killpg(p.pid,sig)
            except (ProcessLookupError,PermissionError): pass
            if sig==signal.SIGTERM:
                try: p.wait(timeout=1)
                except subprocess.TimeoutExpired: pass
        try: p.wait(timeout=2)
        except subprocess.TimeoutExpired: pass

def codex_snapshot(result, activity):
    windows, details = [], []
    buckets=result.get('rateLimitsByLimitId') or {}
    fallback=result.get('rateLimits')
    if fallback and (fallback.get('limitId') or 'codex') not in buckets: buckets[fallback.get('limitId') or 'codex']=fallback
    for key, bucket in sorted(buckets.items()):
        if not isinstance(bucket,dict): continue
        for name,v in bucket.items():
            if isinstance(v,dict) and ('usedPercent' in v or 'windowDurationMins' in v): windows.append(window(name,v,key+':'))
        individual=bucket.get('individualLimit')
        if isinstance(individual,dict):
            remaining=number(individual.get('remainingPercent'))
            windows.append(window('individual',{'usedPercent':100-remaining if remaining is not None else None,'resetsAt':individual.get('resetsAt')},key+':'))
            details.append(f"{key.capitalize()} individual: used {formatted('used',individual.get('used'))} / {formatted('limit',individual.get('limit'))}")
        credit=bucket.get('credits')
        if isinstance(credit,dict): details.append(f"{key.capitalize()} credits: {'unlimited' if credit.get('unlimited') else credit.get('balance') or 'unavailable'}")
        for field in ('planType','normalModelSlug','spendControlReached','rateLimitReachedType'):
            if bucket.get(field) is not None: details.append(f"{key.capitalize()} {label(field).lower()}: {formatted(field,bucket[field])}")
    if 'ordinaryUsageAllowed' in result: details.append('Ordinary usage allowed: '+formatted('ordinaryUsageAllowed',result['ordinaryUsageAllowed']))
    if activity:
        for k,v in (activity.get('summary') or {}).items():
            if number(v) is not None: details.append('Account '+label(k).lower()+': '+formatted(k,v))
        for item in (activity.get('dailyUsageBuckets') or [])[-14:]:
            if isinstance(item,dict) and number(item.get('tokens')) is not None: details.append('Daily '+str(item.get('startDate',''))+': '+formatted('tokens',item['tokens'])+' tokens')
    else: details.append('Account token activity unavailable')
    return dict(id='codex',windows=windows,capturedAt=time.time(),source='Codex app-server · read-only account API',status='Connected',details=details)

def safe_bridge_payload(data):
    if not isinstance(data,dict): data={}
    data=dict(data)
    for key in ('model','context_window','cost','prompt_cache','rate_limits','effort','thinking'):
        if not isinstance(data.get(key),dict): data[key]={}
    out={'capturedAt':time.time(),'session_id':str(data.get('session_id','unknown'))[:128]}
    model=data.get('model') or {}
    out['model']={k:str(model[k])[:128] for k in ('id','display_name') if isinstance(model.get(k),str)}
    for section,keys in {'context_window':['total_input_tokens','total_output_tokens','context_window_size','used_percentage','remaining_percentage'],'cost':['total_cost_usd','total_duration_ms','total_api_duration_ms','total_lines_added','total_lines_removed'],'prompt_cache':['requests','misses','hit_ratio','cache_write_tokens','miss_recache_tokens','expected_rebuilds','recache_tokens_if_cold']}.items():
        value=data.get(section) or {};out[section]={k:number(value[k]) for k in keys if number(value.get(k)) is not None}
    current=(data.get('context_window') or {}).get('current_usage') or {}
    if not isinstance(current,dict): current={}
    out['current_usage']={k:number(current[k]) for k in ('input_tokens','output_tokens','cache_read_input_tokens','cache_creation_input_tokens') if number(current.get(k)) is not None}
    out['rate_limits']={}
    for key,value in (data.get('rate_limits') or {}).items():
        if isinstance(value,dict): out['rate_limits'][str(key)[:80]]={k:number(value[k]) for k in ('used_percentage','resets_at','used_usd','limit_usd') if number(value.get(k)) is not None}
    for key,value in (data.get('rate_limits') or {}).items():
        if isinstance(value,dict) and isinstance(value.get('period'),str): out['rate_limits'][str(key)[:80]]['period']=value['period'][:40]
    for key in ('effort','thinking'):
        value=data.get(key) or {}
        if isinstance(value,dict): out[key]={k:v for k,v in value.items() if k in ('level','enabled') and isinstance(v,(str,bool))}
    if isinstance(data.get('fast_mode'),bool): out['fast_mode']=data['fast_mode']
    return out

def is_own_command(command):
    return isinstance(command,str) and 'usageglass_backend.py' in command

def run_previous(command, raw):
    # Existing trusted user configuration, with process-group deadline and output cap.
    with tempfile.TemporaryFile() as input_file:
        input_file.write(raw);input_file.seek(0)
        proc=subprocess.Popen(command,shell=True,env={**os.environ,'USAGEGLASS_BRIDGE':'1'},stdin=input_file,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,start_new_session=True)
        sel=selectors.DefaultSelector();sel.register(proc.stdout,selectors.EVENT_READ)
        end=time.monotonic()+3;output=b''
        try:
            while time.monotonic()<end and len(output)<65536:
                if not sel.select(0.1): continue
                part=os.read(proc.stdout.fileno(),min(4096,65536-len(output)))
                if not part: break
                output+=part
        finally:
            sel.close()
            try: os.killpg(proc.pid,signal.SIGKILL)
            except ProcessLookupError: pass
            proc.wait()
        sys.stdout.buffer.write(output)

def bridge():
    raw=sys.stdin.buffer.read(MAX_BYTES+1)
    try:
        if len(raw)<=MAX_BYTES:
            fresh=safe_bridge_payload(json.loads(raw))
            if not fresh.get('rate_limits'):
                try:
                    old=read_json(BASE/'claude-usage.json')
                    if old.get('rate_limits'): fresh['rate_limits']=old['rate_limits'];fresh['limitsCapturedAt']=old.get('limitsCapturedAt',old.get('capturedAt'))
                except Exception: pass
            else: fresh['limitsCapturedAt']=fresh['capturedAt']
            atomic(BASE/'claude-usage.json',fresh)
    except Exception: pass
    try:
        previous=read_json(BASE/'bridge-state.json').get('previous')
        if isinstance(previous,dict) and previous.get('type')=='command' and isinstance(previous.get('command'),str) and not is_own_command(previous['command']) and not os.environ.get('USAGEGLASS_BRIDGE'):
            # Run the user's unchanged pre-existing status line, never interpolate JSON.
            run_previous(previous['command'],raw)
        else: print('Usage Glass connected')
    except Exception: pass

def install():
    if SETTINGS.is_symlink() or BASE.is_symlink(): raise ValueError('unsafe path')
    settings=read_json(SETTINGS) if SETTINGS.exists() else {}
    if not isinstance(settings,dict): raise ValueError('settings')
    script=BASE/'usageglass_backend.py'
    command='/usr/bin/python3 -I '+"'"+str(script).replace("'","'\\''")+"' --bridge"
    desired=dict(settings.get('statusLine') or {})
    desired.update(type='command',command=command)
    state=BASE/'bridge-state.json'
    if state.exists():
        saved=read_json(state)
        if settings.get('statusLine')==saved.get('installed'): return 'Bridge already installed. Start or refresh a Claude Code session.'
        raise ValueError('existing installation changed')
    prior=settings.get('statusLine')
    if isinstance(prior,dict) and is_own_command(prior.get('command')):
        raise ValueError('bridge command already present without saved state; remove it from settings first')
    original=SETTINGS.read_bytes() if SETTINGS.exists() else b'{}'
    atomic(BASE/'settings.before-usageglass.json',original,True)
    atomic(script,pathlib.Path(__file__).read_bytes(),True)
    atomic(state,{'previous':settings.get('statusLine'),'hadPrevious':'statusLine' in settings,'installed':desired})
    settings['statusLine']=desired
    try: atomic(SETTINGS,settings)
    except Exception:
        try: state.unlink()
        except OSError: pass
        raise
    return 'Bridge installed. Start or refresh a Claude Code session to receive usage.'

def uninstall():
    state=read_json(BASE/'bridge-state.json');settings=read_json(SETTINGS)
    if settings.get('statusLine')!=state['installed']: raise ValueError('status line changed')
    if state['hadPrevious']: settings['statusLine']=state['previous']
    else: settings.pop('statusLine',None)
    original=(BASE/'settings.before-usageglass.json').read_bytes()
    try: exact=json.loads(original)==settings
    except ValueError: exact=False
    atomic(SETTINGS,original if exact else settings,exact)
    (BASE/'bridge-state.json').unlink()
    return 'Bridge removed; previous status line restored. Backup retained locally.'

def claude_token_stats(now=None):
    """Token activity from local Claude Code transcripts for several spans. This is activity, not quota."""
    now=now or time.time()
    midnight=datetime.datetime.fromtimestamp(now).replace(hour=0,minute=0,second=0,microsecond=0).timestamp()
    spans=(('tokens_5h','Last 5 hours',now-5*3600),('tokens_today','Today',midnight),('tokens_7d','Last 7 days',now-7*86400))
    fields=('input_tokens','output_tokens','cache_creation_input_tokens','cache_read_input_tokens')
    seen={};partial=False
    for modified,path in recent_files(HOME/'.claude/projects',60):
        if now-modified>7*86400: continue
        try: records,truncated=read_tail(path)
        except (OSError,ValueError): continue
        partial=partial or truncated
        for row in records:
            if not isinstance(row,dict) or row.get('type')!='assistant': continue
            message=row.get('message') or {};usage=message.get('usage');mid=message.get('id')
            ts=timestamp(row.get('timestamp'))
            if not isinstance(usage,dict) or not mid or ts is None or message.get('model')=='<synthetic>': continue
            key=(mid,row.get('requestId'))
            vals={f:number(usage.get(f)) or 0 for f in fields}
            size=vals['input_tokens']+vals['output_tokens']+vals['cache_creation_input_tokens']
            if key in seen and seen[key]['size']>=size: continue
            seen[key]=dict(ts=ts,size=size,model=str(message.get('model') or 'unknown')[:64],session=path.stem,**vals)
    if not seen: return [],False
    stats=[]
    for sid,name,start in spans:
        rows=[r for r in seen.values() if r['ts']>=start]
        total=lambda f:int(sum(r[f] for r in rows))
        by_model={}
        for r in rows: by_model[r['model']]=by_model.get(r['model'],0)+r['size']
        reads,fresh,writes=total('cache_read_input_tokens'),total('input_tokens'),total('cache_creation_input_tokens')
        context=reads+fresh+writes
        stats.append(dict(id=sid,label=name,total=total('input_tokens')+total('output_tokens')+writes,input=fresh,output=total('output_tokens'),cacheWrite=writes,cacheRead=reads,
            messages=len(rows),sessions=len({r['session'] for r in rows}),cacheHitRatio=(reads/context if context else None),
            models=[dict(model=m,tokens=int(t)) for m,t in sorted(by_model.items(),key=lambda x:-x[1])[:4]],partial=partial))
    return stats,partial

def claude_snapshot():
    stats,partial=[],False
    try: stats,partial=claude_token_stats()
    except Exception: pass
    try: data=read_json(BASE/'claude-usage.json')
    except Exception:
        if stats:
            return dict(id='claude',windows=[],tokenStats=stats,capturedAt=time.time(),source='Local Claude Code transcripts',status='Token activity only · connect the bridge for quota %'+(' (partial)' if partial else ''),details=['Quota percentages need the Claude status-line bridge (Connections).']),[]
        return dict(id='claude',windows=[],source='Claude supported status-line bridge',status='Waiting for bridge',details=['Limits appear after a Claude API response for supported subscriptions.']),[]
    windows=[window(k,v) for k,v in data.get('rate_limits',{}).items()]
    details=[]
    for section in ('cost','prompt_cache','effort','thinking'):
        for k,v in data.get(section,{}).items(): details.append(label(section)+' · '+label(k)+': '+formatted(k,v))
    for k,v in data.get('rate_limits',{}).items():
        for field in ('used_usd','limit_usd','period'):
            if field in v: details.append(label(k)+' · '+label(field)+': '+formatted(field,v[field]))
    if 'fast_mode' in data: details.append('Fast mode: '+formatted('fast_mode',data['fast_mode']))
    context=data.get('context_window',{});current=data.get('current_usage',{})
    session=dict(id='claude-live-'+data.get('session_id','unknown'),provider='claude',model=data.get('model',{}).get('id'),updatedAt=data['capturedAt'],inputTokens=current.get('input_tokens'),outputTokens=current.get('output_tokens'),cachedInputTokens=current.get('cache_read_input_tokens'),cacheCreationTokens=current.get('cache_creation_input_tokens'),contextUsedPercent=context.get('used_percentage'),contextWindow=context.get('context_window_size'),costUSD=data.get('cost',{}).get('total_cost_usd'),scope='Latest response context · cost is session total')
    # Limits only refresh while Claude Code is active: keep the last reading visible and say how old it is.
    for w in windows:
        reset=w.get('resetsAt')
        if reset is not None and reset<time.time(): w['usedPercent']=None; w['note']='Window reset since last reading'
    return dict(id='claude',windows=windows,tokenStats=stats,capturedAt=data['capturedAt'],source='Claude supported status-line bridge',status='Connected' if windows else 'Connected · limits unavailable',details=details),[session]

def recent_files(root,limit=40):
    if not root.exists(): return []
    found=[];stack=[root];visited=0
    while stack and visited<50000:
        directory=stack.pop()
        try:
            for entry in os.scandir(directory):
                visited+=1
                if visited>50000: break
                if entry.is_symlink(): continue
                if entry.is_dir(follow_symlinks=False): stack.append(pathlib.Path(entry.path))
                elif entry.name.endswith('.jsonl'): found.append((entry.stat().st_mtime,pathlib.Path(entry.path)))
        except OSError: continue
    return sorted(found,reverse=True)[:limit]

def read_tail(path):
    with path.open('rb') as f:
        size=os.fstat(f.fileno()).st_size;truncated=size>MAX_BYTES
        if truncated: f.seek(-MAX_BYTES,2);f.readline()
        raw=f.read(MAX_BYTES)
    records=[]
    for line in raw.splitlines():
        try: records.append(json.loads(line))
        except (ValueError,UnicodeError): pass
    return records,truncated

def local_sessions():
    sessions=[]
    # Recent Codex date folders only: avoid traversing a lifetime of archived sessions.
    roots=[]
    for delta in range(7):
        d=datetime.date.today()-datetime.timedelta(days=delta)
        roots.append(HOME/'.codex/sessions'/d.strftime('%Y/%m/%d'))
    files=sorted([x for root in roots for x in recent_files(root,12)],reverse=True)[:30]
    for modified,path in files:
        try:
            records,truncated=read_tail(path);model=None;usage=None;context=None;sid=path.stem
            for row in records:
                if not isinstance(row,dict): continue
                p=row.get('payload') or {}
                if row.get('type')=='session_meta': sid=p.get('id',sid)
                if row.get('type')=='turn_context': model=p.get('model',model)
                if row.get('type')=='event_msg' and p.get('type')=='token_count':
                    info=p.get('info') or {}
                    if info.get('total_token_usage'): usage=info['total_token_usage'];context=info.get('model_context_window')
            if usage: sessions.append(dict(id='codex-'+sid,provider='codex',model=model,updatedAt=modified,inputTokens=number(usage.get('input_tokens')),outputTokens=number(usage.get('output_tokens')),cachedInputTokens=number(usage.get('cached_input_tokens')),reasoningTokens=number(usage.get('reasoning_output_tokens')),contextWindow=number(context),scope='Cumulative session tokens · model shown is latest, totals may span models'))
        except (OSError,ValueError,AttributeError): continue
    for modified,path in recent_files(HOME/'.claude/projects',30):
        try:
            records,truncated=read_tail(path);messages={};model=None
            for row in records:
                if not isinstance(row,dict): continue
                if row.get('type')!='assistant': continue
                message=row.get('message') or {};usage=message.get('usage')
                mid=message.get('id');rid=row.get('requestId')
                if isinstance(usage,dict) and mid:
                    if message.get('model')=='<synthetic>' and not any(number(usage.get(k)) for k in ('input_tokens','output_tokens','cache_read_input_tokens','cache_creation_input_tokens')): continue
                    messages[(mid,rid)]=usage;model=('System-generated usage' if message.get('model')=='<synthetic>' else message.get('model',model))
            if messages:
                sums={k:sum(number(v.get(k)) or 0 for v in messages.values()) if any(number(v.get(k)) is not None for v in messages.values()) else None for k in ('input_tokens','output_tokens','cache_read_input_tokens','cache_creation_input_tokens')}
                sessions.append(dict(id='claude-'+path.stem,provider='claude',model=model,updatedAt=modified,inputTokens=sums['input_tokens'],outputTokens=sums['output_tokens'],cachedInputTokens=sums['cache_read_input_tokens'],cacheCreationTokens=sums['cache_creation_input_tokens'],scope=('Partial recent transcript' if truncated else 'Local transcript')+' · unique API messages; model shown is latest, totals may span models'))
        except (OSError,ValueError,AttributeError): continue
    unique={s['id']:s for s in sorted(sessions,key=lambda s:s['updatedAt'])}
    return sorted(unique.values(),key=lambda s:s['updatedAt'],reverse=True)[:60]

def collect():
    try:
        answers=codex_response()
        if not answers.get(2): raise RuntimeError('no quota')
        codex=codex_snapshot(answers[2],answers.get(3))
        thread=(answers.get(4) or {}).get('threadUsage')
        if isinstance(thread,dict):
            codex['details'].append('Latest local task '+str(thread.get('threadId','unavailable'))+' · estimated billing usage (not quota)')
            for field in ('estimatedUsageCreditsMicros','estimatedUsageUsdMicros'):
                if number(thread.get(field)) is not None: codex['details'].append(label(field)+': '+formatted(field,thread[field]))
            for group in thread.get('groups',[]):
                if isinstance(group,dict):
                    fields=('model','reasoningEffort','speed','inputTokens','cachedInputTokens','netNewInputTokens','outputTokens','totalTokens','estimatedUsageCreditsMicros')
                    codex['details'].append('Task group · '+' · '.join(label(k)+': '+formatted(k,group[k]) for k in fields if group.get(k) is not None))
        else: codex['details'].append('Latest task billing breakdown unavailable')
    except Exception: codex=dict(id='codex',windows=[],source='Codex app-server',status='Unavailable',error='Unable to read quota. Open Codex and confirm you are signed in.',details=[])
    try: claude,live=claude_snapshot()
    except Exception: claude,live=dict(id='claude',windows=[],source='Claude supported status-line bridge',status='Invalid bridge snapshot',details=[]),[]
    cache=BASE/'session-cache.json'
    try:
        cached=read_json(cache)
        sessions=cached['sessions'] if time.time()-cached['capturedAt']<300 and cached.get('version')==2 else None
    except Exception: sessions=None
    if sessions is None:
        sessions=local_sessions()
        try: atomic(cache,{'version':2,'capturedAt':time.time(),'sessions':sessions})
        except Exception: pass
    return {'snapshots':[codex,claude],'sessions':live+sessions,'bridgeStatus':'Bridge installed · waiting for Claude activity' if (BASE/'bridge-state.json').exists() else 'Bridge not installed'}

if __name__=='__main__':
    action=sys.argv[1] if len(sys.argv)>1 else '--collect'
    if action=='--bridge': bridge()
    else:
        try:
            if action=='--install': result={'message':install()}
            elif action=='--uninstall': result={'message':uninstall()}
            elif action in ('--collect','--diagnostics'):
                result=collect()
                if action=='--diagnostics': result={'providers':[{'provider':s['id'],'status':s['status'],'windows':s['windows']} for s in result['snapshots']],'sessionCount':len(result['sessions'])}
            else: raise ValueError('unknown action')
            print(json.dumps(result,allow_nan=False))
        except Exception: print(json.dumps({'error':'Operation could not complete safely. Existing settings were preserved; inspect connection setup and permissions.'}))
