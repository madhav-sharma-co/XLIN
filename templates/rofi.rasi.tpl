/* XLIN launcher: Start-menu style, bottom left */
* {
  bg:     @C_PANEL_HEX@;
  soft:   @C_SOFT@;
  ink:    @C_INK@;
  muted:  @C_MUTED@;
  accent: @C_ACCENT@;
  font:   "@C_FONT@ @C_PT11@";
}

window {
  /* centered above the dock */
  location: south;
  anchor: south;
  x-offset: 0px;
  y-offset: -78px;
  width: 600px;
  padding: 16px;
  background-color: @bg;
  border: 1px;
  border-color: @C_LINE_SOLID@;
  border-radius: 11px;
}

mainbox {
  children: [ inputbar, message, listview ];
  spacing: 14px;
  background-color: transparent;
}

inputbar {
  children: [ entry ];
  padding: 11px 13px;
  background-color: @soft;
  border-radius: 8px;
}

entry {
  placeholder: "Search apps";
  placeholder-color: @muted;
  text-color: @ink;
  background-color: transparent;
}

message {
  background-color: transparent;
  text-color: @muted;
}
textbox { text-color: @muted; background-color: transparent; }

listview {
  columns: 5;
  lines: 3;
  fixed-columns: true;
  fixed-height: true;
  cycle: false;
  spacing: 6px;
  scrollbar: false;
  background-color: transparent;
}

element {
  orientation: vertical;
  padding: 12px 4px 8px 4px;
  spacing: 6px;
  border-radius: 8px;
  background-color: transparent;
  text-color: @ink;
}
element selected.normal { background-color: @soft; text-color: @ink; }
element-icon { size: 44px; horizontal-align: 0.5; background-color: transparent; }
element-text {
  horizontal-align: 0.5;
  vertical-align: 0.5;
  background-color: transparent;
  text-color: inherit;
  font: "@C_FONT@ Bold @C_PT9@";
}
