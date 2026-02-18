"""
SmartQuail Database Handler
===========================
Handles all Supabase database operations
"""

from supabase import create_client, Client
from datetime import datetime, timedelta
import pandas as pd
from typing import Optional, List, Dict, Any
import config

# Initialize Supabase client
supabase: Client = create_client(config.SUPABASE_URL, config.SUPABASE_KEY)

def insert_sensor_data(data: Dict[str, Any]) -> bool:
    """Insert sensor data into database"""
    try:
        record = {
            "device": data.get("device", "esp32-01"),
            "temp": float(data.get("temp", 0)),
            "rh": float(data.get("rh", 0)),
            "thi": float(data.get("thi", 0)),
            "relay": data.get("relay", "OFF"),
            "status": data.get("status", "OK")
        }
        supabase.table("sensor_logs").insert(record).execute()
        return True
    except Exception as e:
        print(f"[DB ERROR] Insert failed: {e}")
        return False

def get_latest_data(device: str = "esp32-01") -> Optional[Dict[str, Any]]:
    """Get the most recent sensor reading"""
    try:
        response = supabase.table("sensor_logs")\
            .select("*")\
            .eq("device", device)\
            .order("created_at", desc=True)\
            .limit(1)\
            .execute()
        
        if response.data:
            return response.data[0]
        return None
    except Exception as e:
        print(f"[DB ERROR] Get latest failed: {e}")
        return None

def get_history_data(
    device: str = "esp32-01",
    hours: int = 24,
    limit: int = 1000
) -> pd.DataFrame:
    """Get historical sensor data"""
    try:
        since = (datetime.utcnow() - timedelta(hours=hours)).isoformat()
        
        response = supabase.table("sensor_logs")\
            .select("*")\
            .eq("device", device)\
            .gte("created_at", since)\
            .order("created_at", desc=False)\
            .limit(limit)\
            .execute()
        
        if response.data:
            df = pd.DataFrame(response.data)
            df['created_at'] = pd.to_datetime(df['created_at'])
            return df
        
        return pd.DataFrame()
    except Exception as e:
        print(f"[DB ERROR] Get history failed: {e}")
        return pd.DataFrame()

def get_statistics(device: str = "esp32-01", hours: int = 24) -> Dict[str, Any]:
    """Calculate statistics for the given time period"""
    df = get_history_data(device, hours)
    
    if df.empty:
        return {
            "temp": {"avg": 0, "min": 0, "max": 0},
            "rh": {"avg": 0, "min": 0, "max": 0},
            "thi": {"avg": 0, "min": 0, "max": 0},
            "relay_on_count": 0,
            "data_points": 0
        }
    
    return {
        "temp": {
            "avg": round(df["temp"].mean(), 1),
            "min": round(df["temp"].min(), 1),
            "max": round(df["temp"].max(), 1)
        },
        "rh": {
            "avg": round(df["rh"].mean(), 1),
            "min": round(df["rh"].min(), 1),
            "max": round(df["rh"].max(), 1)
        },
        "thi": {
            "avg": round(df["thi"].mean(), 1),
            "min": round(df["thi"].min(), 1),
            "max": round(df["thi"].max(), 1)
        },
        "relay_on_count": len(df[df["relay"] == "ON"]),
        "data_points": len(df)
    }

def get_device_list() -> List[str]:
    """Get list of all devices"""
    try:
        response = supabase.table("sensor_logs")\
            .select("device")\
            .execute()
        
        if response.data:
            devices = list(set([d["device"] for d in response.data]))
            return sorted(devices)
        return ["esp32-01"]
    except Exception as e:
        print(f"[DB ERROR] Get devices failed: {e}")
        return ["esp32-01"]

def export_to_csv(device: str = "esp32-01", hours: int = 24) -> str:
    """Export data to CSV string"""
    df = get_history_data(device, hours)
    if not df.empty:
        return df.to_csv(index=False)
    return ""

def get_data_count(device: str = "esp32-01") -> int:
    """Get total data count for device"""
    try:
        response = supabase.table("sensor_logs")\
            .select("id", count="exact")\
            .eq("device", device)\
            .execute()
        return response.count if response.count else 0
    except Exception as e:
        print(f"[DB ERROR] Get count failed: {e}")
        return 0
