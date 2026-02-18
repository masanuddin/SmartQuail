"""
SmartQuail - IoT Dashboard for Quail House Monitoring
Apple-inspired UI, bilingual (ID/EN), Supabase + MQTT.
"""

from datetime import datetime

import streamlit as st
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

from config import (
    REFRESH_INTERVAL_SEC,
    HISTORY_HOURS,
    THI_NORMAL_MAX,
    THI_WARNING_MAX,
    SUPABASE_URL,
)
from supabase_client import get_latest_reading, get_history
from mqtt_listener import start_mqtt_thread
from i18n import t

# Page config - first thing
st.set_page_config(
    page_title="SmartQuail",
    page_icon="🐦",
    layout="wide",
    initial_sidebar_state="collapsed",
)

# Start MQTT in background (writes to Supabase)
start_mqtt_thread()

# Language in session state
if "lang" not in st.session_state:
    st.session_state.lang = "id"
lang = st.session_state.lang


def apply_apple_style():
    st.markdown("""
    <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
    
    .stApp { background: linear-gradient(180deg, #f5f5f7 0%, #e8e8ed 100%); }
    .main .block-container { padding: 1.5rem 2rem; max-width: 1400px; }
    
    .smartquail-header {
        text-align: center;
        padding: 1rem 0 1.5rem;
        font-family: 'Inter', -apple-system, sans-serif;
    }
    .smartquail-header h1 {
        font-size: clamp(1.5rem, 4vw, 2.2rem);
        font-weight: 700;
        color: #1d1d1f;
        letter-spacing: -0.02em;
        margin: 0;
    }
    .smartquail-header p { color: #6e6e73; font-size: 0.95rem; margin-top: 0.25rem; }
    
    .kpi-card {
        background: rgba(255,255,255,0.72);
        backdrop-filter: blur(12px);
        -webkit-backdrop-filter: blur(12px);
        border-radius: 16px;
        padding: 1.25rem;
        text-align: center;
        box-shadow: 0 4px 24px rgba(0,0,0,0.06);
        border: 1px solid rgba(255,255,255,0.8);
        transition: transform 0.2s, box-shadow 0.2s;
    }
    .kpi-card:hover { transform: translateY(-2px); box-shadow: 0 8px 32px rgba(0,0,0,0.08); }
    
    .kpi-value { font-size: clamp(1.5rem, 3vw, 2rem); font-weight: 700; color: #1d1d1f; }
    .kpi-label { font-size: 0.8rem; color: #6e6e73; margin-top: 0.25rem; text-transform: uppercase; letter-spacing: 0.04em; }
    
    .status-bar {
        background: rgba(255,255,255,0.72);
        backdrop-filter: blur(12px);
        border-radius: 12px;
        padding: 0.9rem 1.25rem;
        margin: 1rem 0;
        box-shadow: 0 4px 24px rgba(0,0,0,0.06);
        border: 1px solid rgba(255,255,255,0.8);
        font-weight: 500;
    }
    .status-ok { color: #34c759; }
    .status-warning { color: #ff9500; }
    .status-danger { color: #ff3b30; }
    
    .section-title { font-size: 1rem; font-weight: 600; color: #1d1d1f; margin-bottom: 0.5rem; }
    
    [data-testid="stMetricValue"] { font-size: 1.5rem !important; }
    
    @media (max-width: 640px) {
        .main .block-container { padding: 1rem; }
        .kpi-card { padding: 1rem; }
    }
    </style>
    """, unsafe_allow_html=True)


def get_thi_status(thi: float):
    if thi <= THI_NORMAL_MAX:
        return "ok", "status_ok"
    if thi <= THI_WARNING_MAX:
        return "warning", "status_warning"
    return "danger", "status_danger"


def render_header(lang: str):
    apply_apple_style()
    col_logo, col_title, col_lang = st.columns([1, 4, 1])
    with col_logo:
        try:
            st.image("smartquail.png", width=56)
        except Exception:
            st.markdown("<div style='height:56px;display:flex;align-items:center;'>🐦</div>", unsafe_allow_html=True)
    with col_title:
        st.markdown(f"""
        <div class="smartquail-header">
            <h1>🐦 {t("title", lang)}</h1>
            <p>{t("subtitle", lang)}</p>
        </div>
        """, unsafe_allow_html=True)
    with col_lang:
        other = "en" if lang == "id" else "id"
        if st.button(t("lang_switch", lang), key="lang_btn", use_container_width=True):
            st.session_state.lang = other
            st.rerun()


def render_kpis(row: dict, lang: str):
    temp = row.get("temp")
    rh = row.get("rh")
    thi = row.get("thi")
    relay = (row.get("relay") or "OFF").upper()
    if temp is None:
        temp = rh = thi = "--"
        relay = "-"
    else:
        temp = f"{temp}°C"
        rh = f"{rh}%"
        thi = f"{thi}"
    c1, c2, c3, c4 = st.columns(4)
    for col, val, label in [
        (c1, temp, t("temp", lang)),
        (c2, rh, t("humidity", lang)),
        (c3, thi, t("thi", lang)),
        (c4, "🟢 " + relay if relay == "ON" else "⚪ " + relay, t("relay", lang)),
    ]:
        with col:
            st.markdown(f"""
            <div class="kpi-card">
                <div class="kpi-value">{val}</div>
                <div class="kpi-label">{label}</div>
            </div>
            """, unsafe_allow_html=True)


def render_status_bar(thi_val, lang: str):
    if thi_val is None:
        status_class = "status-ok"
        msg = t("no_data", lang)
    else:
        level, key = get_thi_status(thi_val)
        status_class = f"status-{level}"
        msg = t(key, lang)
    st.markdown(f"""
    <div class="status-bar {status_class}">
        <strong>STATUS:</strong> {msg}
    </div>
    """, unsafe_allow_html=True)


def render_trend_chart(history: list, lang: str):
    if not history:
        st.info(t("no_data", lang))
        return
    df = pd.DataFrame(history)
    df["created_at"] = pd.to_datetime(df["created_at"])
    df = df.sort_values("created_at")
    fig = make_subplots(
        rows=2, cols=1,
        shared_xaxes=True,
        vertical_spacing=0.08,
        subplot_titles=(t("temp", lang), t("humidity", lang)),
    )
    fig.add_trace(go.Scatter(x=df["created_at"], y=df["temp"], name=t("temp", lang), line=dict(color="#007AFF", width=2)), row=1, col=1)
    fig.add_trace(go.Scatter(x=df["created_at"], y=df["rh"], name=t("humidity", lang), line=dict(color="#34c759", width=2)), row=2, col=1)
    fig.update_layout(
        height=280,
        margin=dict(l=50, r=30, t=40, b=40),
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(255,255,255,0.6)",
        font=dict(family="Inter, sans-serif", size=12),
        showlegend=False,
    )
    fig.update_xaxes(showgrid=True, gridwidth=1, gridcolor="rgba(0,0,0,0.06)")
    fig.update_yaxes(showgrid=True, gridwidth=1, gridcolor="rgba(0,0,0,0.06)")
    st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})


def render_thi_gauge(thi_val: float, lang: str):
    if thi_val is None:
        thi_val = 0
    if thi_val <= THI_NORMAL_MAX:
        color = "#34c759"
    elif thi_val <= THI_WARNING_MAX:
        color = "#ff9500"
    else:
        color = "#ff3b30"
    fig = go.Figure(go.Indicator(
        mode="gauge+number",
        value=thi_val,
        number={"suffix": "", "font": {"size": 36}},
        gauge={
            "axis": {"range": [0, 100], "tickwidth": 1},
            "bar": {"color": color},
            "bgcolor": "rgba(255,255,255,0.6)",
            "borderwidth": 0,
            "steps": [
                {"range": [0, THI_NORMAL_MAX], "color": "rgba(52, 199, 89, 0.25)"},
                {"range": [THI_NORMAL_MAX, THI_WARNING_MAX], "color": "rgba(255, 149, 0, 0.25)"},
                {"range": [THI_WARNING_MAX, 100], "color": "rgba(255, 59, 48, 0.25)"},
            ],
            "threshold": {
                "line": {"color": color, "width": 4},
                "thickness": 0.8,
                "value": thi_val,
            },
        },
        title={"text": t("gauge_title", lang), "font": {"size": 14}},
    ))
    fig.update_layout(
        height=220,
        margin=dict(l=40, r=40, t=50, b=30),
        paper_bgcolor="rgba(0,0,0,0)",
        font=dict(family="Inter, sans-serif"),
    )
    st.plotly_chart(fig, use_container_width=True, config={"displayModeBar": False})
    st.caption(f"{t('zone_normal', lang)} &lt;{THI_NORMAL_MAX}  |  {t('zone_warning', lang)} {THI_NORMAL_MAX}-{THI_WARNING_MAX}  |  {t('zone_danger', lang)} &gt;{THI_WARNING_MAX}")


# --- Main flow ---
render_header(lang)

# Data from Supabase (or demo if no Supabase)
latest = get_latest_reading()
history = get_history(hours=min(1, HISTORY_HOURS)) if latest else []

if not latest and not SUPABASE_URL:
    # Demo row when no Supabase configured
    latest = {
        "device": "esp32-01",
        "temp": 28.3,
        "rh": 72,
        "thi": 78.9,
        "relay": "ON",
        "status": "OK",
        "created_at": datetime.utcnow().isoformat(),
    }

render_kpis(latest or {}, lang)
thi_val = latest.get("thi") if latest else None
render_status_bar(thi_val, lang)

st.markdown(f'<p class="section-title">📈 {t("trend_title", lang)}</p>', unsafe_allow_html=True)
render_trend_chart(history, lang)

st.markdown(f'<p class="section-title">📊 {t("gauge_title", lang)}</p>', unsafe_allow_html=True)
render_thi_gauge(thi_val, lang)

if latest and latest.get("created_at"):
    try:
        ts = pd.to_datetime(latest["created_at"])
        st.caption(f"{t('last_update', lang)}: {ts.strftime('%H:%M:%S')} ({t('device', lang)}: {latest.get('device','-')})")
    except Exception:
        pass

# Auto refresh every REFRESH_INTERVAL_SEC (non-blocking)
try:
    from streamlit_autorefresh import st_autorefresh
    st_autorefresh(interval=REFRESH_INTERVAL_SEC * 1000, key="smartquail_refresh")
except Exception:
    pass
