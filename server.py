#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import logging
import os
import tempfile
from email.parser import BytesParser
from email.policy import default
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import whisper


MODEL_CACHE: dict[str, object] = {}


def load_model(model_name: str):
    if model_name not in MODEL_CACHE:
        logging.info("Loading Whisper model '%s'", model_name)
        MODEL_CACHE[model_name] = whisper.load_model(model_name)

    return MODEL_CACHE[model_name]


def parse_multipart(content_type: str, body: bytes) -> tuple[dict[str, str], dict[str, dict[str, bytes | str]]]:
    message = BytesParser(policy=default).parsebytes(
        f"Content-Type: {content_type}\r\nMIME-Version: 1.0\r\n\r\n".encode("utf-8") + body
    )

    if not message.is_multipart():
        raise ValueError("Expected multipart/form-data request body.")

    fields: dict[str, str] = {}
    files: dict[str, dict[str, bytes | str]] = {}

    for part in message.iter_parts():
        name = part.get_param("name", header="content-disposition")
        if not name:
            continue

        filename = part.get_filename()
        payload = part.get_payload(decode=True) or b""

        if filename:
            files[name] = {
                "filename": filename,
                "content": payload,
                "content_type": part.get_content_type(),
            }
            continue

        fields[name] = payload.decode(part.get_content_charset("utf-8")).strip()

    return fields, files


class WhisperHandler(BaseHTTPRequestHandler):
    server_version = "OrtioWhisper/1.0"

    def do_GET(self) -> None:
        if self.path == "/health":
            self.respond_json(200, {"status": "ok", "models": list(MODEL_CACHE.keys())})
            return

        self.respond_json(404, {"error": "Not found"})

    def do_POST(self) -> None:
        if self.path.rstrip("/") != "/v1/audio/transcriptions":
            self.respond_json(404, {"error": "Not found"})
            return

        try:
            content_type = self.headers.get("Content-Type", "")
            if "multipart/form-data" not in content_type:
                raise ValueError("Expected multipart/form-data request.")

            content_length = int(self.headers.get("Content-Length", "0"))
            body = self.rfile.read(content_length)
            fields, files = parse_multipart(content_type, body)

            upload = files.get("file")
            if not upload:
                raise ValueError("Missing audio file upload.")

            model_name = fields.get("model") or os.environ.get("WHISPER_MODEL", "turbo")
            task = fields.get("task") or "transcribe"
            if task != "transcribe":
                raise ValueError("Only task=transcribe is supported.")

            language = fields.get("language") or None
            file_name = str(upload.get("filename") or "audio.m4a")
            suffix = Path(file_name).suffix or ".m4a"
            file_bytes = bytes(upload["content"])

            with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_audio:
                temp_audio.write(file_bytes)
                temp_path = temp_audio.name

            try:
                model = load_model(model_name)
                result = model.transcribe(
                    temp_path,
                    task="transcribe",
                    language=language,
                    verbose=False,
                )
            finally:
                try:
                    os.remove(temp_path)
                except OSError:
                    pass

            text = str(result.get("text", "")).strip()
            if not text:
                raise RuntimeError("Whisper returned an empty transcription.")

            self.respond_json(
                200,
                {
                    "text": text,
                    "language": result.get("language"),
                },
            )
        except ValueError as error:
            self.respond_json(400, {"error": str(error)})
        except Exception as error:  # pragma: no cover - integration/runtime path
            logging.exception("Whisper transcription failed")
            self.respond_json(500, {"error": str(error)})

    def log_message(self, format: str, *args: object) -> None:
        logging.info("%s - %s", self.address_string(), format % args)

    def respond_json(self, status_code: int, payload: dict[str, object]) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run a local Whisper transcription server for Ortio.",
    )
    parser.add_argument("--host", default=os.environ.get("WHISPER_HOST", "0.0.0.0"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("WHISPER_PORT", "8080")))
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="[%(asctime)s] %(message)s")
    server = ThreadingHTTPServer((args.host, args.port), WhisperHandler)
    logging.info("Listening on http://%s:%s", args.host, args.port)
    logging.info("Health check available at http://%s:%s/health", args.host, args.port)
    server.serve_forever()


if __name__ == "__main__":
    main()
