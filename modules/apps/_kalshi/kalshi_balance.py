"""Print the Kalshi cash balance, e.g. "$1,234.56".

Credentials: /run/agenix/kalshi-api (or $KALSHI_API_FILE) holds the API key
id on the first line and the PEM private key after it. Auth per
docs.kalshi.com/getting_started/quick_start_authenticated_requests:
sign "<ms timestamp>GET<full path, no query>"; RSA keys use PSS/SHA-256
with digest-length salt, Ed25519 keys sign the message directly.

`--check` signs and verifies a fixed message with a throwaway key; the
build runs it, so a broken signing path fails the build, not the bar.
"""

import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ed25519, padding, rsa

HOST = "https://external-api.kalshi.com"
PATH = "/trade-api/v2/portfolio/balance"
PSS = padding.PSS(
    mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.DIGEST_LENGTH
)


def sign(key, message: bytes) -> str:
    if isinstance(key, rsa.RSAPrivateKey):
        sig = key.sign(message, PSS, hashes.SHA256())
    elif isinstance(key, ed25519.Ed25519PrivateKey):
        sig = key.sign(message)
    else:
        raise ValueError("unsupported key type (need RSA or Ed25519)")
    return base64.b64encode(sig).decode()


def check() -> None:
    msg = b"1703123456789GET" + PATH.encode()
    rsa_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    sig = base64.b64decode(sign(rsa_key, msg))
    rsa_key.public_key().verify(sig, msg, PSS, hashes.SHA256())
    ed_key = ed25519.Ed25519PrivateKey.generate()
    ed_key.public_key().verify(base64.b64decode(sign(ed_key, msg)), msg)
    assert fmt(123456) == "$1,234.56" and fmt(5) == "$0.05"
    print("ok")


def fmt(cents: int) -> str:
    return f"${cents / 100:,.2f}"


def main() -> int:
    if sys.argv[1:] == ["--check"]:
        check()
        return 0
    path = os.environ.get("KALSHI_API_FILE", "/run/agenix/kalshi-api")
    try:
        with open(path, "rb") as f:
            key_id, pem = f.read().split(b"\n", 1)
        key = serialization.load_pem_private_key(pem.strip(), password=None)
    except (OSError, ValueError) as e:
        print(f"bad credentials: {e}")
        return 1
    ts = str(int(time.time() * 1000))
    req = urllib.request.Request(
        HOST + PATH,
        headers={
            "KALSHI-ACCESS-KEY": key_id.decode().strip(),
            "KALSHI-ACCESS-TIMESTAMP": ts,
            "KALSHI-ACCESS-SIGNATURE": sign(key, f"{ts}GET{PATH}".encode()),
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            print(fmt(json.load(r)["balance"]))
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code}: {e.read(200).decode(errors='replace')}")
        return 1
    except (urllib.error.URLError, OSError, KeyError, ValueError) as e:
        print(f"request failed: {e}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
