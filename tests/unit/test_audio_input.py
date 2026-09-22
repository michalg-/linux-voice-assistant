"""Tests for command-based audio input."""

import io
from unittest.mock import MagicMock, patch

import numpy as np
import pytest

from linux_voice_assistant.audio_input import CommandMicrophone


def test_command_microphone_reads_interleaved_s16le():
    samples = np.array([[1, -1], [32767, -32768]], dtype="<i2")
    process = MagicMock()
    process.stdout = io.BytesIO(samples.tobytes())
    process.poll.return_value = None

    with patch("linux_voice_assistant.audio_input.subprocess.Popen", return_value=process) as popen:
        mic = CommandMicrophone("parec --raw --channels=2")
        with mic.recorder(samplerate=16000, channels=2, blocksize=2) as recorder:
            result = recorder.record(2)

    popen.assert_called_once_with(["parec", "--raw", "--channels=2"], stdout=-1, bufsize=0)
    assert result.dtype == np.dtype("<i2")
    np.testing.assert_array_equal(result, samples)
    process.terminate.assert_called_once()


def test_command_microphone_rejects_empty_command():
    with pytest.raises(ValueError, match="must not be empty"):
        CommandMicrophone("   ")


def test_command_microphone_reports_early_exit():
    process = MagicMock()
    process.stdout = io.BytesIO(b"\x01\x00")
    process.poll.return_value = 7

    with patch("linux_voice_assistant.audio_input.subprocess.Popen", return_value=process):
        mic = CommandMicrophone("parec --raw")
        with mic.recorder(samplerate=16000, channels=1, blocksize=2) as recorder:
            with pytest.raises(RuntimeError, match="exit code 7"):
                recorder.record(2)
