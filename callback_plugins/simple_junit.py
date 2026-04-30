from ansible.plugins.callback import CallbackBase
import time
#import yaml
import os

def dict_to_yaml(data, indent=0):
    lines = []
    spacing = "  " * indent

    for key, value in data.items():
        if isinstance(value, dict):
            # Write the key and recurse for the nested dict
            lines.append(f"{spacing}{key}:")
            lines.append(dict_to_yaml(value, indent + 1))
        elif isinstance(value, list):
            # Write the key and iterate through the list
            lines.append(f"{spacing}{key}:")
            for item in value:
                lines.append(f"{spacing}  - {item}")
        else:
            # Handle strings, numbers, and Booleans
            if isinstance(value, str):
                # Simple check for strings that might need quotes
                if ":" in value or "#" in value:
                    value = f'"{value}"'
            lines.append(f"{spacing}{key}: {value}")

    return "\n".join(lines)

class CallbackModule(CallbackBase):
    """
    Simple JUnit + YAML reporting callback
    """

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'notification'
    CALLBACK_NAME = 'simple_junit'

    def __init__(self):
        super().__init__()
        self.tests = []
        self.start_times = {}

    # -------------------------
    # TASK START
    # -------------------------
    def v2_runner_on_start(self, host, task):
        self.start_times[task._uuid] = time.time()

    # -------------------------
    # SUCCESS
    # -------------------------
    def v2_runner_on_ok(self, result):
        self._record(result, "success")

    # -------------------------
    # FAILURE
    # -------------------------
    def v2_runner_on_failed(self, result, ignore_errors=False):
        self._record(result, "failure")

    # -------------------------
    # RECORD TEST
    # -------------------------
    def _record(self, result, status):
        task = result._task
        name = task.name  # clean name only

        start = self.start_times.get(task._uuid, None)
        duration = round(time.time() - start, 3) if start else 0

        self.tests.append({
            "test name": name,
            "test result": status,
            "time": duration
        })

    # -------------------------
    # WRITE OUTPUTS
    # -------------------------
    def v2_playbook_on_stats(self, stats):
        self._write_file()
        self._write_junit()

    # -------------------------
    # YAML OUTPUT
    # -------------------------
    def _write_file(self):
        import json
        output = {"tests": self.tests}

        outdir = os.environ.get("JUNIT_OUTPUT_DIR", "/tmp")
        outfile = os.path.join(outdir, "results.yaml")

        os.makedirs(outdir, exist_ok=True)

        with open(outfile, "w") as f:
            #yaml.dump(output, f, sort_keys=False)
            #f.write(dict_to_yaml(output))
            json.dump(output, file)

    # -------------------------
    # JUNIT OUTPUT (keep if you already use it)
    # -------------------------
    def _write_junit(self):
        # keep your existing XML logic here if needed
        pass
