import re
import os
import subprocess
from typing import List


def exec_process(args: List[str], pipe: bool) -> bytes:
	kwargs = {}
	if pipe:
		kwargs = {
			"stdout": subprocess.PIPE,
			"stderr": subprocess.PIPE,
		}

	proc = subprocess.Popen(args, **kwargs)
	output, _ = proc.communicate()

	try:
		proc.kill()
	except Exception:
		pass

	return output


def decompress(fname: str):
	swfdump = exec_process(["./swfdump", "-a", fname], True)
	ignore_line = rb"[^\n]*?\n"

	character_map = re.search(
		rb'(?s)'
		rb'findproperty <q>\[(?:private|public)\](?:NULL|)::(?:.*?)\n'
		rb'(?:.*?)pushstring "(.*?)"\n',
		swfdump
	).group(1)

	aliases = {
		match.group(1): character_map[int(match.group(2))]
		for match in re.finditer(
			rb'<q>\[public\]::Object <q>\[private\]NULL::(.*?)=\(\)\(0 params, 0 optional\)' +
			ignore_line * 6 +
			rb'[^\n]*?push(?:byte|short|int) (\d+)',
			swfdump
		)
	}

	scrambled_script = bytes(
		aliases[match.group(1)]
		for match in re.finditer(
			rb'getlocal_0' + ignore_line +
			rb'.*?callproperty <q>\[(?:private|public)\](?:NULL|)::(.*?), 0 params',
			swfdump
		)
	)

	binary_names = {
		match.group(2): int(match.group(1))
		for match in re.finditer(
			rb'\s+exports (\d+) as "(?:.*?)_(.*?)"'
		)
	}

	exec_process(["swfbinexport", fname], False)

	fname = os.path.splitext(fname)[0]
	with open("./Transformice.swf", "wb") as swf:
		for match in re.finditer(
			rb'writeBytes(' + (b"|".join(binary_names.keys())) + rb')',
			scrambled_script
		):
			with open(f"./{fname}-{binary_names[match.group(1)]}.bin", "rb") as bin:
				swf.write(bin.read())


if __name__ == "__main__":
	decompress("Transformice-compressed.swf")
