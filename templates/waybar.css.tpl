* {
  font-family: "@C_FONT@", "Inter", "Symbols Nerd Font", "Font Awesome 7 Free", "Font Awesome 6 Free", sans-serif;
  font-size: @C_FS_BAR@px;
  border: none;
  border-radius: 0;
  min-height: 0;
}

window#waybar {
  background: @C_TOPBAR@;
  color: @C_INK@;
  border-bottom: 1px solid @C_TOPBAR_LINE@;
}

tooltip {
  background: @C_PANEL@;
  border: 1px solid @C_LINE_SOLID@;
  border-radius: 8px;
}
tooltip label { color: @C_INK@; }

#custom-xlin {
  margin: 5px 4px 5px 10px;
  min-width: 30px;
  padding: 0 9px;
  border-radius: 6px;
  background: @C_HOVER@;
  border: 1px solid @C_TOPBAR_LINE@;
  color: @C_INK@;
  font-family: "Inter", sans-serif;
  font-size: @C_FS_BAR_X@px;
  font-weight: 800;
}
#custom-xlin:hover { background: @C_ACCENT_SOFT@; color: @C_ACCENT@; }

#window {
  margin-left: 10px;
  font-weight: 700;
}

#network, #battery, #pulseaudio, #custom-settings, #custom-tools, #custom-session, #bluetooth {
  padding: 0 7px;
  color: @C_INK@;
}
#network.disconnected { opacity: 0.3; }
#battery.charging { color: #3fae6a; }
#battery.warning { color: #d5953e; }
#battery.critical { color: #e05555; }

#clock {
  padding: 0 8px;
  font-size: @C_FS_BAR_SM@px;
  font-weight: 600;
}
#clock:hover { background: @C_HOVER@; border-radius: 7px; }

#custom-panel {
  margin: 6px 12px 6px 4px;
  padding: 0 8px;
  border-radius: 7px;
}
#custom-panel:hover { background: @C_HOVER@; }
