# Merge new INI settings into an existing INI file, section by section.
# Usage: awk -f merge-ini.awk NEW_SETTINGS FILE > RESULT

function key_of(line) {
  return substr(line, 1, index(line, "=") - 1)
}

function value_of(line) {
  return substr(line, index(line, "=") + 1)
}

function is_section(line) {
  return line ~ /^\[/
}

# Reset the section at the start of each file
FNR == 1 {
  section = ""
}

# First file: remember the new settings
FNR == NR {
  if (is_section($0)) {
    section = $0
    if (!(section in new_lines)) {
      section_count++
      section_order[section_count] = section
      new_lines[section] = ""
    }
    next
  }

  if ($0 !~ /=/) {
    next
  }

  key = key_of($0)
  value = value_of($0)
  gsub(/\\/, "\\\\", value)
  # Qt reads a bare comma as a list
  if (value ~ /,/) {
    value = "\"" value "\""
  }

  new_lines[section] = new_lines[section] key "=" value "\n"
  is_new_key[section, key] = 1
  next
}

# Second file: copy it, with the new keys right after their section header
is_section($0) {
  section = $0
  found_section[section] = 1
  print
  printf "%s", new_lines[section]
  next
}

(section, key_of($0)) in is_new_key {
  next
}

{
  print
}

# Sections that were not in the file go at the end
END {
  for (i = 1; i <= section_count; i++) {
    section = section_order[i]
    if (!(section in found_section)) {
      printf "\n%s\n%s", section, new_lines[section]
    }
  }
}
