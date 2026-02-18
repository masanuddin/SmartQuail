"""
SmartQuail - Supabase client for storing and fetching IoT readings.
Table: readings (id, device, temp, rh, thi, relay, status, created_at)
Create table in Supabase SQL Editor (see README).
"""

import os
from datetime import datetime, timedelta
from typing import Optional

try:
    from supabase import create_client, Client
except ImportError:
    create_client = None
    Client = None

from config import SUPABASE_URL, SUPABASE_KEY, HISTORY_HOURS


def get_client() -> Optional["Client"]:
    if not create_client or not SUPABASE_URL or not SUPABASE_KEY:
        return None
    return create_client(SUPABASE_URL, SUPABASE_KEY)


def insert_reading(device: str, temp: float, rh: float, thi: float, relay: str, status: str) -> bool:
    """Insert one reading. Returns True if success."""
    client = get_client()
    if not client:
        return False
    try:
        client.table("readings").insert({
            "device": device,
            "temp": round(temp, 1),
            "rh": round(rh, 1),
            "thi": round(thi, 1),
            "relay": relay,
            "status": status,
        }).execute()
        return True
    except Exception:
        return False


def get_latest_reading(device: str = "esp32-01"):
    """Get latest reading for device. Returns dict or None."""
    client = get_client()
    if not client:
        return None
    try:
        since = (datetime.utcnow() - timedelta(hours=HISTORY_HOURS)).isoformat()
        r = (
            client.table("readings")
            .select("*")
            .eq("device", device)
            .gte("created_at", since)
            .order("created_at", desc=True)
            .limit(1)
            .execute()
        )
        if r.data and len(r.data) > 0:
            return r.data[0]
        return None
    except Exception:
        return None


def get_history(device: str = "esp32-01", hours: int = None):
    """Get readings for last N hours. Returns list of dicts."""
    client = get_client()
    if not client:
        return []
    hours = hours or HISTORY_HOURS
    since = (datetime.utcnow() - timedelta(hours=hours)).isoformat()
    try:
        r = (
            client.table("readings")
            .select("created_at, temp, rh, thi, relay, status")
            .eq("device", device)
            .gte("created_at", since)
            .order("created_at", desc=False)
            .execute()
        )
        return r.data or []
    except Exception:
        return []
