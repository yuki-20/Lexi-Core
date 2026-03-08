"""
LexiCore API Key Encryption Utility
Run once to encrypt the API key. The encrypted key is stored in config.
Only the admin (who sets LEXI_ADMIN_KEY env var) can decrypt it at runtime.

Usage:
  python -m engine.encrypt_key
"""
import os, sys, base64, hashlib
from cryptography.fernet import Fernet


def derive_key(password: str) -> bytes:
    """Derive a Fernet-compatible key from an admin password."""
    dk = hashlib.pbkdf2_hmac("sha256", password.encode(), b"LexiCoreAI_Salt", 100_000)
    return base64.urlsafe_b64encode(dk)


def encrypt_api_key(api_key: str, admin_password: str) -> str:
    key = derive_key(admin_password)
    f = Fernet(key)
    return f.encrypt(api_key.encode()).decode()


def decrypt_api_key(encrypted_key: str, admin_password: str) -> str:
    key = derive_key(admin_password)
    f = Fernet(key)
    return f.decrypt(encrypted_key.encode()).decode()


if __name__ == "__main__":
    print("═══ LexiCore API Key Encryption ═══")
    admin_pw = input("Enter admin password: ").strip()
    if not admin_pw:
        print("Error: admin password cannot be empty")
        sys.exit(1)

    raw_key = "sk-EeQBT1pVXYW2RtDd4Cwn8dirRT8ZH2XPIJ9pgAJ58DyMLP4O"
    encrypted = encrypt_api_key(raw_key, admin_pw)

    config_path = os.path.join(os.path.dirname(__file__), "ai_config.json")
    import json
    with open(config_path, "w") as fp:
        json.dump({"encrypted_api_key": encrypted, "base_url": "https://mkp-api.fptcloud.com/v1/chat/completions"}, fp, indent=2)

    print(f"\n✅ Encrypted key saved to: {config_path}")
    print(f"   Set LEXI_ADMIN_KEY={admin_pw} as env variable to unlock at runtime.")

    # Verify
    decrypted = decrypt_api_key(encrypted, admin_pw)
    assert decrypted == raw_key, "Decryption verification failed!"
    print("   Decryption verified ✓")
