"""Check production jamovi option routing without starting or cancelling an R job.

Run inside the jamovi server Python environment. Optional arguments are .a.yaml
paths; by default this checks this repository's Rj and Rjp definitions.
"""
from pathlib import Path
from types import SimpleNamespace
import sys
import yaml
from jamovi.server.options import Options
from jamovi.server.analyses.analysis import Analysis
from jamovi.server import jamovi_pb2 as pb

root = Path(__file__).resolve().parents[1]
paths = [Path(arg) for arg in sys.argv[1:]] or [root / 'jamovi/rj.a.yaml', root / 'jamovi/rjp.a.yaml']
for path in paths:
    definitions = yaml.safe_load(path.read_text(encoding='utf-8'))['options']
    for status in (Analysis.Status.RUNNING, Analysis.Status.COMPLETE, Analysis.Status.ERROR):
        options = Options.create(definitions)
        incoming = Options.create(definitions)
        notifications = []
        state = SimpleNamespace(enabled=True, options=options, _outputs_synced={},
            results=pb.AnalysisResponse(), complete=status == Analysis.Status.COMPLETE,
            _status=status, changes=set(),
            parent=SimpleNamespace(_notify_options_changed=lambda analysis: notifications.append(analysis)))
        incoming.set_value('editorState', {'draft': 'edited draft', 'hasDraft': True})
        Analysis.set_options(state, incoming.as_pb(), [], revision=1)
        assert not notifications and state._status == status, (path, status)
        # Active submitted code is different: the Run path must request execution.
        incoming.set_value('code', 'submitted code')
        Analysis.set_options(state, incoming.as_pb(), [], revision=2)
        assert len(notifications) == 1 and state._status == Analysis.Status.NONE
    print(f'{path.name}: draft edits do not restart/cancel RUNNING, COMPLETE or ERROR analyses; submitted code does request execution: PASSED')
