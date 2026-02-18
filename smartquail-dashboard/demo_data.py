"""
SmartQuail Demo Data Generator
==============================
Generate sample data for testing dashboard without ESP32

Usage:
    python demo_data.py
"""

import random
import time
from datetime import datetime
import database as db

def generate_demo_data():
    """Generate realistic demo sensor data"""
    
    # Base values with some randomness
    base_temp = 26 + random.uniform(-2, 6)  # 24-32°C
    base_rh = 65 + random.uniform(-10, 20)  # 55-85%
    
    # Calculate THI
    thi = (0.8 * base_temp) + ((base_rh / 100) * (base_temp - 14.4)) + 46.4
    
    # Determine relay status based on THI
    relay = "ON" if thi >= 80 else "OFF"
    
    data = {
        "device": "esp32-01",
        "temp": round(base_temp, 1),
        "rh": round(base_rh, 0),
        "thi": round(thi, 1),
        "relay": relay,
        "status": "OK"
    }
    
    return data

def main():
    print("=" * 60)
    print("🐦 SmartQuail Demo Data Generator")
    print("=" * 60)
    print("Generating data every 2 seconds...")
    print("Press Ctrl+C to stop.\n")
    
    count = 0
    
    try:
        while True:
            # Generate data
            data = generate_demo_data()
            count += 1
            
            # Print
            timestamp = datetime.now().strftime("%H:%M:%S")
            print(f"[{timestamp}] #{count} | Temp: {data['temp']}°C | RH: {data['rh']}% | THI: {data['thi']} | Relay: {data['relay']}")
            
            # Save to database
            success = db.insert_sensor_data(data)
            if success:
                print(f"           └── ✅ Saved to Supabase")
            else:
                print(f"           └── ❌ Failed to save")
            
            # Wait
            time.sleep(2)
            
    except KeyboardInterrupt:
        print(f"\n\n[👋] Stopped. Generated {count} data points.")

if __name__ == "__main__":
    main()
