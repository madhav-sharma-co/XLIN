window {
  background: transparent;
}

#box {
  padding: 6px 8px;
  background: @C_DOCK@;
  border: 1px solid @C_DOCK_LINE@;
  border-radius: 11px;
}

button, image {
  background: none;
  border-style: none;
  box-shadow: none;
  color: @C_INK@;
}

button {
  padding: 3px;
  margin: 0 2px;
  border-radius: 8px;
  transition: all 0.16s ease;
}

button:hover {
  background: @C_HOVER@;
}

#active {
  background: @C_ACCENT_SOFT@;
}
