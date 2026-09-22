"""Alternative audio input backends."""

import logging
import shlex
import subprocess
import time
from types import TracebackType
from typing import Optional, Type

import numpy as np

_LOGGER = logging.getLogger(__name__)


class CommandMicrophone:
    """Microphone backed by a command that writes signed 16-bit PCM."""

    def __init__(self, command: str) -> None:
        self.command = shlex.split(command)
        if not self.command:
            raise ValueError("Audio input command must not be empty")
        self.name = shlex.join(self.command)

    def recorder(self, samplerate: int, channels: int, blocksize: int) -> "CommandRecorder":
        return CommandRecorder(self.command, samplerate, channels, blocksize)


class CommandRecorder:
    """Read fixed-size audio blocks from a subprocess."""

    def __init__(self, command: list[str], samplerate: int, channels: int, blocksize: int) -> None:
        self.command = command
        self.samplerate = samplerate
        self.channels = channels
        self.blocksize = blocksize
        self._process: Optional[subprocess.Popen[bytes]] = None

    def __enter__(self) -> "CommandRecorder":
        self._start_process()
        return self

    def __exit__(
        self,
        exc_type: Optional[Type[BaseException]],
        exc_value: Optional[BaseException],
        traceback: Optional[TracebackType],
    ) -> None:
        self._stop_process()

    def record(self, numframes: int) -> np.ndarray:
        process = self._process
        if process is None or process.stdout is None:
            raise RuntimeError("Audio input command is not running")

        expected_bytes = numframes * self.channels * 2
        audio = bytearray()
        while len(audio) < expected_bytes:
            chunk = process.stdout.read(expected_bytes - len(audio))
            if not chunk:
                return_code = process.poll()
                _LOGGER.warning("Audio input command stopped unexpectedly (exit code %s); restarting", return_code)
                self._stop_process()
                time.sleep(1)
                self._start_process()
                process = self._process
                assert process is not None and process.stdout is not None
                audio.clear()
                continue
            audio.extend(chunk)

        return np.frombuffer(audio, dtype="<i2").reshape(numframes, self.channels)

    def _start_process(self) -> None:
        self._process = subprocess.Popen(self.command, stdout=subprocess.PIPE, bufsize=0)

    def _stop_process(self) -> None:
        process = self._process
        self._process = None
        if process is None:
            return

        if process.stdout is not None:
            process.stdout.close()
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
        else:
            process.wait()
