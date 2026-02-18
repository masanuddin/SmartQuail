"""
SmartQuail Dashboard
====================
Intelligent Aviary Monitoring System
Apple-Inspired Design with Real-time MQTT Data

Authors: Ricky Rudiansyah, Marcellino Asanuddin
Supervisor: Prof. Dr. Ir. Widodo Budiharto
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta
import time
import json
import base64
from pathlib import Path

# Import local modules
import config
import database as db

# =============================================================================
# PAGE CONFIG
# =============================================================================
st.set_page_config(
    page_title="SmartQuail Dashboard",
    page_icon="🐦",
    layout="wide",
    initial_sidebar_state="expanded"
)

# =============================================================================
# LOAD CUSTOM CSS
# =============================================================================
def load_css():
    css_file = Path(__file__).parent / "styles" / "apple_style.css"
    if css_file.exists():
        with open(css_file) as f:
            st.markdown(f"<style>{f.read()}</style>", unsafe_allow_html=True)
    
    # Additional inline styles for Streamlit components
    st.markdown("""
    <style>
        /* Hide default Streamlit elements */
        #MainMenu {visibility: hidden;}
        footer {visibility: hidden;}
        
        /* Custom font */
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
        
        html, body, [class*="css"] {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
        }
        
        /* Metric styling */
        [data-testid="stMetricValue"] {
            font-size: 2.5rem !important;
            font-weight: 600 !important;
        }
        
        [data-testid="stMetricLabel"] {
            font-size: 0.875rem !important;
            font-weight: 500 !important;
            text-transform: uppercase !important;
            letter-spacing: 0.5px !important;
        }
        
        /* Card container */
        .element-container {
            transition: all 0.25s ease;
        }
        
        /* Remove padding from columns */
        .stColumn > div {
            padding: 0 0.5rem;
        }
    </style>
    """, unsafe_allow_html=True)

load_css()

# =============================================================================
# SESSION STATE
# =============================================================================
if 'language' not in st.session_state:
    st.session_state.language = 'id'

if 'last_data' not in st.session_state:
    st.session_state.last_data = None

if 'history_hours' not in st.session_state:
    st.session_state.history_hours = 24

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================
def t(key: str) -> str:
    """Translate text based on current language"""
    return config.get_text(key, st.session_state.language)

def get_thi_status(thi: float) -> tuple:
    """Get THI status and color"""
    if thi < config.THI_NORMAL:
        return "normal", "#34C759", t("normal")
    elif thi < config.THI_WARNING:
        return "warning", "#FFCC00", t("warning")
    elif thi < config.THI_DANGER:
        return "danger", "#FF3B30", t("danger")
    else:
        return "critical", "#AF52DE", t("critical")

def get_logo_base64():
    """Get logo as base64 for embedding"""
    logo_path = Path(__file__).parent / "assets" / "smartquail.png"
    if logo_path.exists():
        with open(logo_path, "rb") as f:
            return base64.b64encode(f.read()).decode()
    return None

def format_timestamp(ts):
    """Format timestamp for display"""
    if isinstance(ts, str):
        ts = datetime.fromisoformat(ts.replace('Z', '+00:00'))
    return ts.strftime("%H:%M:%S")

def create_gauge_chart(value: float, title: str, min_val: float = 0, max_val: float = 100) -> go.Figure:
    """Create Apple-style gauge chart"""
    status, color, _ = get_thi_status(value)
    
    fig = go.Figure(go.Indicator(
        mode="gauge+number",
        value=value,
        number={'font': {'size': 48, 'color': '#1D1D1F', 'family': 'Inter'}, 'suffix': ''},
        gauge={
            'axis': {
                'range': [min_val, max_val],
                'tickwidth': 2,
                'tickcolor': "#E5E5EA",
                'tickfont': {'size': 12, 'color': '#86868B'}
            },
            'bar': {'color': color, 'thickness': 0.75},
            'bgcolor': "white",
            'borderwidth': 0,
            'steps': [
                {'range': [0, config.THI_NORMAL], 'color': 'rgba(52, 199, 89, 0.15)'},
                {'range': [config.THI_NORMAL, config.THI_WARNING], 'color': 'rgba(255, 204, 0, 0.15)'},
                {'range': [config.THI_WARNING, 100], 'color': 'rgba(255, 59, 48, 0.15)'}
            ],
            'threshold': {
                'line': {'color': "#1D1D1F", 'width': 3},
                'thickness': 0.8,
                'value': value
            }
        }
    ))
    
    fig.update_layout(
        height=250,
        margin=dict(l=20, r=20, t=40, b=20),
        paper_bgcolor='rgba(0,0,0,0)',
        plot_bgcolor='rgba(0,0,0,0)',
        font={'family': 'Inter'}
    )
    
    return fig

def create_line_chart(df: pd.DataFrame, y_columns: list, colors: list, title: str) -> go.Figure:
    """Create Apple-style line chart"""
    fig = go.Figure()
    
    for col, color in zip(y_columns, colors):
        if col in df.columns:
            fig.add_trace(go.Scatter(
                x=df['created_at'],
                y=df[col],
                mode='lines',
                name=col.upper(),
                line=dict(color=color, width=2.5, shape='spline'),
                fill='tozeroy',
                fillcolor=f'rgba({int(color[1:3], 16)}, {int(color[3:5], 16)}, {int(color[5:7], 16)}, 0.1)'
            ))
    
    fig.update_layout(
        height=350,
        margin=dict(l=0, r=0, t=20, b=0),
        paper_bgcolor='rgba(0,0,0,0)',
        plot_bgcolor='rgba(0,0,0,0)',
        xaxis=dict(
            showgrid=True,
            gridcolor='rgba(0,0,0,0.05)',
            tickfont=dict(size=11, color='#86868B'),
            showline=False
        ),
        yaxis=dict(
            showgrid=True,
            gridcolor='rgba(0,0,0,0.05)',
            tickfont=dict(size=11, color='#86868B'),
            showline=False
        ),
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=1.02,
            xanchor="right",
            x=1,
            font=dict(size=12)
        ),
        hovermode='x unified',
        font={'family': 'Inter'}
    )
    
    return fig

def create_area_chart(df: pd.DataFrame) -> go.Figure:
    """Create THI area chart with zones"""
    fig = go.Figure()
    
    # Add THI line
    fig.add_trace(go.Scatter(
        x=df['created_at'],
        y=df['thi'],
        mode='lines',
        name='THI',
        line=dict(color='#007AFF', width=3, shape='spline'),
        fill='tozeroy',
        fillcolor='rgba(0, 122, 255, 0.1)'
    ))
    
    # Add threshold lines
    fig.add_hline(y=config.THI_NORMAL, line_dash="dash", line_color="#34C759", 
                  annotation_text="Normal", annotation_position="right")
    fig.add_hline(y=config.THI_WARNING, line_dash="dash", line_color="#FFCC00",
                  annotation_text="Warning", annotation_position="right")
    
    fig.update_layout(
        height=300,
        margin=dict(l=0, r=60, t=20, b=0),
        paper_bgcolor='rgba(0,0,0,0)',
        plot_bgcolor='rgba(0,0,0,0)',
        xaxis=dict(
            showgrid=True,
            gridcolor='rgba(0,0,0,0.05)',
            tickfont=dict(size=11, color='#86868B')
        ),
        yaxis=dict(
            showgrid=True,
            gridcolor='rgba(0,0,0,0.05)',
            tickfont=dict(size=11, color='#86868B'),
            range=[50, 100]
        ),
        showlegend=False,
        hovermode='x unified',
        font={'family': 'Inter'}
    )
    
    return fig

# =============================================================================
# COMPONENTS
# =============================================================================
def render_metric_card(label: str, value: str, unit: str = "", status: str = "normal", icon: str = ""):
    """Render Apple-style metric card"""
    status_colors = {
        "normal": "#34C759",
        "warning": "#FFCC00", 
        "danger": "#FF3B30",
        "info": "#007AFF",
        "active": "#007AFF"
    }
    color = status_colors.get(status, "#007AFF")
    
    st.markdown(f"""
    <div style="
        background: white;
        border-radius: 16px;
        padding: 1.5rem;
        box-shadow: 0 4px 12px rgba(0,0,0,0.08);
        border: 1px solid rgba(0,0,0,0.04);
        border-top: 4px solid {color};
        transition: all 0.25s ease;
        height: 100%;
    ">
        <div style="
            font-size: 0.875rem;
            font-weight: 500;
            color: #86868B;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 0.5rem;
        ">{icon} {label}</div>
        <div style="
            font-size: 2.5rem;
            font-weight: 600;
            color: #1D1D1F;
            line-height: 1.1;
        ">{value}<span style="font-size: 1rem; font-weight: 400; color: #86868B; margin-left: 4px;">{unit}</span></div>
    </div>
    """, unsafe_allow_html=True)

def render_status_banner(status: str, message: str, status_type: str = "success"):
    """Render status banner"""
    icons = {
        "success": "✅",
        "warning": "⚠️",
        "error": "🚨",
        "info": "ℹ️"
    }
    colors = {
        "success": ("rgba(52, 199, 89, 0.1)", "rgba(52, 199, 89, 0.3)", "#248A3D"),
        "warning": ("rgba(255, 204, 0, 0.1)", "rgba(255, 204, 0, 0.3)", "#B25000"),
        "error": ("rgba(255, 59, 48, 0.1)", "rgba(255, 59, 48, 0.3)", "#D70015"),
        "info": ("rgba(0, 122, 255, 0.1)", "rgba(0, 122, 255, 0.3)", "#0066CC")
    }
    bg, border, text = colors.get(status_type, colors["info"])
    icon = icons.get(status_type, "ℹ️")
    
    st.markdown(f"""
    <div style="
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 1rem 1.25rem;
        border-radius: 12px;
        background: {bg};
        border: 1px solid {border};
        color: {text};
        font-weight: 500;
        margin: 0.5rem 0;
    ">
        <span style="font-size: 1.25rem;">{icon}</span>
        <div>
            <div style="font-weight: 600;">{status}</div>
            <div style="font-size: 0.875rem; opacity: 0.9;">{message}</div>
        </div>
    </div>
    """, unsafe_allow_html=True)

def render_relay_status(relay: str):
    """Render relay status indicator"""
    is_on = relay.upper() == "ON"
    color = "#007AFF" if is_on else "#86868B"
    bg = "rgba(0, 122, 255, 0.12)" if is_on else "rgba(142, 142, 147, 0.12)"
    status_text = t("on") if is_on else t("off")
    
    st.markdown(f"""
    <div style="
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 10px 20px;
        border-radius: 100px;
        background: {bg};
        color: {color};
        font-weight: 600;
        font-size: 0.9375rem;
    ">
        <span style="
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: {color};
            {'animation: pulse 2s infinite;' if is_on else ''}
        "></span>
        {status_text}
    </div>
    <style>
        @keyframes pulse {{
            0%, 100% {{ opacity: 1; transform: scale(1); }}
            50% {{ opacity: 0.7; transform: scale(1.15); }}
        }}
    </style>
    """, unsafe_allow_html=True)

# =============================================================================
# SIDEBAR
# =============================================================================
def render_sidebar():
    """Render sidebar with settings"""
    with st.sidebar:
        # Logo
        logo_b64 = get_logo_base64()
        if logo_b64:
            st.markdown(f"""
            <div style="
                display: flex;
                align-items: center;
                gap: 12px;
                margin-bottom: 1.5rem;
                padding-bottom: 1.5rem;
                border-bottom: 1px solid #E5E5EA;
            ">
                <img src="data:image/png;base64,{logo_b64}" style="width: 56px; height: 56px; border-radius: 12px;">
                <div>
                    <div style="font-size: 1.25rem; font-weight: 600; color: #1D1D1F;">SmartQuail</div>
                    <div style="font-size: 0.75rem; color: #86868B;">Intelligent Monitoring</div>
                </div>
            </div>
            """, unsafe_allow_html=True)
        else:
            st.markdown("## 🐦 SmartQuail")
        
        st.markdown("---")
        
        # Language selector
        st.markdown(f"### 🌐 {t('language')}")
        lang_options = {"🇮🇩 Bahasa Indonesia": "id", "🇬🇧 English": "en"}
        current_lang = "🇮🇩 Bahasa Indonesia" if st.session_state.language == "id" else "🇬🇧 English"
        selected_lang = st.selectbox(
            "Select Language",
            options=list(lang_options.keys()),
            index=0 if st.session_state.language == "id" else 1,
            label_visibility="collapsed"
        )
        st.session_state.language = lang_options[selected_lang]
        
        st.markdown("---")
        
        # History range
        st.markdown(f"### 📊 {t('history')}")
        st.session_state.history_hours = st.slider(
            f"{t('history')} ({t('hours')})",
            min_value=1,
            max_value=72,
            value=st.session_state.history_hours,
            label_visibility="collapsed"
        )
        
        st.markdown("---")
        
        # Optimal ranges info
        st.markdown(f"### 🎯 {t('optimal_range')}")
        st.markdown(f"""
        <div style="
            background: #F5F5F7;
            border-radius: 12px;
            padding: 1rem;
            font-size: 0.875rem;
        ">
            <div style="margin-bottom: 0.75rem;">
                <div style="color: #86868B; font-size: 0.75rem;">🌡️ {t('temperature')}</div>
                <div style="font-weight: 600; color: #1D1D1F;">{config.TEMP_MIN_OPTIMAL}°C - {config.TEMP_MAX_OPTIMAL}°C</div>
            </div>
            <div style="margin-bottom: 0.75rem;">
                <div style="color: #86868B; font-size: 0.75rem;">💧 {t('humidity')}</div>
                <div style="font-weight: 600; color: #1D1D1F;">{config.HUMIDITY_MIN_OPTIMAL}% - {config.HUMIDITY_MAX_OPTIMAL}%</div>
            </div>
            <div>
                <div style="color: #86868B; font-size: 0.75rem;">📈 THI {t('normal')}</div>
                <div style="font-weight: 600; color: #1D1D1F;">< {config.THI_NORMAL}</div>
            </div>
        </div>
        """, unsafe_allow_html=True)
        
        st.markdown("---")
        
        # Download button
        st.markdown(f"### 💾 {t('download')}")
        df = db.get_history_data(hours=st.session_state.history_hours)
        if not df.empty:
            csv = df.to_csv(index=False)
            st.download_button(
                label=f"📥 Download CSV",
                data=csv,
                file_name=f"smartquail_data_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                mime="text/csv",
                use_container_width=True
            )
        
        st.markdown("---")
        
        # Footer
        st.markdown("""
        <div style="
            text-align: center;
            font-size: 0.75rem;
            color: #86868B;
            margin-top: 1rem;
        ">
            <div>SmartQuail v1.0</div>
            <div style="margin-top: 4px;">BINUS University © 2025</div>
        </div>
        """, unsafe_allow_html=True)

# =============================================================================
# MAIN DASHBOARD
# =============================================================================
def render_dashboard():
    """Render main dashboard"""
    
    # Header
    col1, col2 = st.columns([3, 1])
    with col1:
        st.markdown(f"""
        <h1 style="
            font-size: 2rem;
            font-weight: 700;
            color: #1D1D1F;
            margin: 0;
        ">{t('title')}</h1>
        <p style="
            font-size: 1rem;
            color: #86868B;
            margin: 0.25rem 0 1.5rem 0;
        ">{t('subtitle')}</p>
        """, unsafe_allow_html=True)
    
    with col2:
        st.markdown(f"""
        <div style="text-align: right; padding-top: 0.5rem;">
            <div style="font-size: 0.75rem; color: #86868B;">{t('last_update')}</div>
            <div style="font-size: 0.875rem; font-weight: 500; color: #1D1D1F;">{datetime.now().strftime('%H:%M:%S')}</div>
        </div>
        """, unsafe_allow_html=True)
    
    # Get latest data
    data = db.get_latest_data()
    
    if data:
        temp = data.get('temp', 0)
        rh = data.get('rh', 0)
        thi = data.get('thi', 0)
        relay = data.get('relay', 'OFF')
        status = data.get('status', 'OK')
        
        # Determine THI status
        thi_status, thi_color, thi_text = get_thi_status(thi)
        
        # Status Banner
        if status == "SENSOR_ERROR":
            render_status_banner(t('sensor_error'), t('check_environment'), "error")
        elif thi >= config.THI_WARNING:
            render_status_banner(t('danger'), t('cooling_active'), "warning")
        else:
            render_status_banner(t('system_status'), t('all_systems_normal'), "success")
        
        st.markdown("<div style='height: 1rem;'></div>", unsafe_allow_html=True)
        
        # Main Metrics Row
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            temp_status = "normal" if config.TEMP_MIN_OPTIMAL <= temp <= config.TEMP_MAX_OPTIMAL else "warning" if temp < 30 else "danger"
            render_metric_card(t('temperature'), f"{temp:.1f}", "°C", temp_status, "🌡️")
        
        with col2:
            rh_status = "normal" if config.HUMIDITY_MIN_OPTIMAL <= rh <= config.HUMIDITY_MAX_OPTIMAL else "warning"
            render_metric_card(t('humidity'), f"{rh:.0f}", "%", rh_status, "💧")
        
        with col3:
            render_metric_card(t('thi'), f"{thi:.1f}", "", thi_status, "📊")
        
        with col4:
            relay_status = "active" if relay.upper() == "ON" else "info"
            st.markdown(f"""
            <div style="
                background: white;
                border-radius: 16px;
                padding: 1.5rem;
                box-shadow: 0 4px 12px rgba(0,0,0,0.08);
                border: 1px solid rgba(0,0,0,0.04);
                border-top: 4px solid {'#007AFF' if relay.upper() == 'ON' else '#86868B'};
                height: 100%;
            ">
                <div style="
                    font-size: 0.875rem;
                    font-weight: 500;
                    color: #86868B;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    margin-bottom: 0.75rem;
                ">💨 {t('relay')}</div>
            """, unsafe_allow_html=True)
            render_relay_status(relay)
            st.markdown("</div>", unsafe_allow_html=True)
        
        st.markdown("<div style='height: 1.5rem;'></div>", unsafe_allow_html=True)
        
        # Charts Row
        col1, col2 = st.columns([2, 1])
        
        with col1:
            st.markdown(f"""
            <div style="
                background: white;
                border-radius: 16px;
                padding: 1.5rem;
                box-shadow: 0 4px 12px rgba(0,0,0,0.08);
                margin-bottom: 1rem;
            ">
                <h3 style="font-size: 1.125rem; font-weight: 600; color: #1D1D1F; margin: 0 0 1rem 0;">
                    📈 {t('temperature')} & {t('humidity')} {t('trend')}
                </h3>
            """, unsafe_allow_html=True)
            
            df = db.get_history_data(hours=st.session_state.history_hours)
            if not df.empty:
                fig = create_line_chart(df, ['temp', 'rh'], ['#FF9500', '#007AFF'], 'Trend')
                st.plotly_chart(fig, use_container_width=True, config={'displayModeBar': False})
            else:
                st.info(t('no_data'))
            
            st.markdown("</div>", unsafe_allow_html=True)
        
        with col2:
            st.markdown(f"""
            <div style="
                background: white;
                border-radius: 16px;
                padding: 1.5rem;
                box-shadow: 0 4px 12px rgba(0,0,0,0.08);
                margin-bottom: 1rem;
            ">
                <h3 style="font-size: 1.125rem; font-weight: 600; color: #1D1D1F; margin: 0 0 0.5rem 0;">
                    🎯 THI {t('current')}
                </h3>
            """, unsafe_allow_html=True)
            
            fig = create_gauge_chart(thi, "THI", 50, 100)
            st.plotly_chart(fig, use_container_width=True, config={'displayModeBar': False})
            
            # THI Legend
            st.markdown(f"""
            <div style="display: flex; justify-content: center; gap: 1rem; font-size: 0.75rem; margin-top: -1rem;">
                <span style="color: #34C759;">● {t('normal')}</span>
                <span style="color: #FFCC00;">● {t('warning')}</span>
                <span style="color: #FF3B30;">● {t('danger')}</span>
            </div>
            """, unsafe_allow_html=True)
            
            st.markdown("</div>", unsafe_allow_html=True)
        
        # THI Trend Chart
        st.markdown(f"""
        <div style="
            background: white;
            border-radius: 16px;
            padding: 1.5rem;
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
            margin-bottom: 1rem;
        ">
            <h3 style="font-size: 1.125rem; font-weight: 600; color: #1D1D1F; margin: 0 0 1rem 0;">
                📊 THI {t('trend')} ({st.session_state.history_hours} {t('hours')})
            </h3>
        """, unsafe_allow_html=True)
        
        if not df.empty:
            fig = create_area_chart(df)
            st.plotly_chart(fig, use_container_width=True, config={'displayModeBar': False})
        else:
            st.info(t('no_data'))
        
        st.markdown("</div>", unsafe_allow_html=True)
        
        # Statistics Row
        st.markdown(f"""
        <div style="
            background: white;
            border-radius: 16px;
            padding: 1.5rem;
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
        ">
            <h3 style="font-size: 1.125rem; font-weight: 600; color: #1D1D1F; margin: 0 0 1rem 0;">
                📊 {t('statistics')} ({st.session_state.history_hours} {t('hours')})
            </h3>
        """, unsafe_allow_html=True)
        
        stats = db.get_statistics(hours=st.session_state.history_hours)
        
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.markdown(f"""
            <div style="text-align: center; padding: 1rem; background: #F5F5F7; border-radius: 12px;">
                <div style="font-size: 0.75rem; color: #86868B; margin-bottom: 0.25rem;">🌡️ {t('temperature')} {t('avg')}</div>
                <div style="font-size: 1.5rem; font-weight: 600; color: #1D1D1F;">{stats['temp']['avg']}°C</div>
                <div style="font-size: 0.75rem; color: #86868B;">{t('min')}: {stats['temp']['min']}° / {t('max')}: {stats['temp']['max']}°</div>
            </div>
            """, unsafe_allow_html=True)
        
        with col2:
            st.markdown(f"""
            <div style="text-align: center; padding: 1rem; background: #F5F5F7; border-radius: 12px;">
                <div style="font-size: 0.75rem; color: #86868B; margin-bottom: 0.25rem;">💧 {t('humidity')} {t('avg')}</div>
                <div style="font-size: 1.5rem; font-weight: 600; color: #1D1D1F;">{stats['rh']['avg']}%</div>
                <div style="font-size: 0.75rem; color: #86868B;">{t('min')}: {stats['rh']['min']}% / {t('max')}: {stats['rh']['max']}%</div>
            </div>
            """, unsafe_allow_html=True)
        
        with col3:
            st.markdown(f"""
            <div style="text-align: center; padding: 1rem; background: #F5F5F7; border-radius: 12px;">
                <div style="font-size: 0.75rem; color: #86868B; margin-bottom: 0.25rem;">📈 THI {t('avg')}</div>
                <div style="font-size: 1.5rem; font-weight: 600; color: #1D1D1F;">{stats['thi']['avg']}</div>
                <div style="font-size: 0.75rem; color: #86868B;">{t('min')}: {stats['thi']['min']} / {t('max')}: {stats['thi']['max']}</div>
            </div>
            """, unsafe_allow_html=True)
        
        with col4:
            st.markdown(f"""
            <div style="text-align: center; padding: 1rem; background: #F5F5F7; border-radius: 12px;">
                <div style="font-size: 0.75rem; color: #86868B; margin-bottom: 0.25rem;">💨 {t('relay')} {t('on')}</div>
                <div style="font-size: 1.5rem; font-weight: 600; color: #1D1D1F;">{stats['relay_on_count']}</div>
                <div style="font-size: 0.75rem; color: #86868B;">Total: {stats['data_points']} data</div>
            </div>
            """, unsafe_allow_html=True)
        
        st.markdown("</div>", unsafe_allow_html=True)
    
    else:
        # No data state
        st.markdown(f"""
        <div style="
            text-align: center;
            padding: 4rem 2rem;
            background: white;
            border-radius: 16px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
        ">
            <div style="font-size: 4rem; margin-bottom: 1rem;">🐦</div>
            <h2 style="color: #1D1D1F; margin-bottom: 0.5rem;">{t('no_data')}</h2>
            <p style="color: #86868B;">{t('loading')} Menunggu data dari ESP32...</p>
        </div>
        """, unsafe_allow_html=True)

# =============================================================================
# MAIN APP
# =============================================================================
def main():
    render_sidebar()
    render_dashboard()
    
    # Auto-refresh every 2 seconds
    time.sleep(config.REFRESH_INTERVAL)
    st.rerun()

if __name__ == "__main__":
    main()
