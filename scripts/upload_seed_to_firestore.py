import json
import urllib.request
import urllib.error

API_KEY = "AIzaSyBobCwA6QK-3g015kwJz73EGbdJLt6NwJs"
PROJECT_ID = "hedge-mikrotrans"
BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

def py_to_firestore(val):
    if val is None:
        return {"nullValue": None}
    if isinstance(val, bool):
        return {"booleanValue": val}
    if isinstance(val, int):
        return {"integerValue": str(val)}
    if isinstance(val, float):
        return {"doubleValue": val}
    if isinstance(val, str):
        return {"stringValue": val}
    if isinstance(val, dict):
        return {"mapValue": {"fields": {k: py_to_firestore(v) for k, v in val.items()}}}
    if isinstance(val, list):
        return {"arrayValue": {"values": [py_to_firestore(x) for x in val]}}
    return {"stringValue": str(val)}

def save_document(collection, doc_id, data):
    url = f"{BASE_URL}/{collection}/{doc_id}?key={API_KEY}"
    fields = {k: py_to_firestore(v) for k, v in data.items()}
    payload = json.dumps({"fields": fields}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, method="PATCH", headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status
    except urllib.error.HTTPError as e:
        print(f"Error saving {collection}/{doc_id}: {e.code} - {e.read().decode()}")
        raise

def main():
    with open("seed_data_firestore.json", "r", encoding="utf-8") as f:
        seed = json.load(f)

    dispatchers = seed.get("dispatchers", [])
    routes = seed.get("routes", [])

    print(f"Uploading {len(dispatchers)} dispatchers...")
    for d in dispatchers:
        email = d.get("email")
        if not email:
            continue
        save_document("authorized_dispatchers", email, d)
        print(f" [OK] Dispatcher: {email} ({d.get('role')} - {d.get('status')})")

    print(f"\nUploading {len(routes)} routes with nested units & drivers...")
    for r in routes:
        doc_id = r.get("uuid") or r.get("route_code")
        save_document("routes", doc_id, r)
        units_count = len(r.get("units", []))
        drivers_count = len(r.get("drivers", []))
        print(f" [OK] Route: {r.get('route_code')} ({doc_id}) -> {units_count} units, {drivers_count} drivers")

    print("\nAll seed data uploaded to Cloud Firestore successfully!")

if __name__ == "__main__":
    main()
