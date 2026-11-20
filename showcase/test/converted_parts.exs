# `data-part` names of the elements of components already MIGRATED to Tailwind utilities.
# For these elements the parity tests ignore `class` (see LedgerShowcase.Parity, "CONVERTED PARTS"):
# they are checked by `python parity/run.py` (pixels) instead. A batch adds ITS parts here, one line per
# component (this is the only shared file a batch edits in showcase/test; add lines, never reorder).
~w(
  button button-spinner button-pip button-group icon-button insight-button insight-button-count
  badge badge-dot badge-remove
  card card-title card-header card-heading card-subheading card-body card-footer card-actions card-bleed
  icon-box
  input input-control input-addon password-toggle
  field label label-row label-required label-optional label-hint field-body field-row error help
  stat stat-group stat-label stat-value stat-unit stat-hint stat-foot stat-delta stat-arrow stat-meter stat-meter-bar stat-spark stat-spark-svg stat-spark-area stat-spark-line stat-spark-dot

  checkbox checkbox-input checkbox-text checkbox-description checkbox-group choice choice-input choice-text choice-label choice-description choice-count choice-tick
  radio radio-input radio-text radio-description radio-group
  switch switch-track switch-text switch-description switch-input
  segmented segmented-item segmented-count
  chip chip-count chip-remove person-avatar person-avatar-image
  pill-select
  textarea textarea-control textarea-wrap textarea-mirror textarea-header textarea-footer textarea-counter textarea-counter-row
  otp otp-cell otp-box otp-dash
  number-input number-value number-minus number-plus number-prefix number-suffix
  password-meter password-meter-bar
  input-group addon
  form-section form-section-head form-section-title form-section-description form-section-fields
  select select-control select-value select-chip select-chip-remove select-search select-clear select-native select-panel select-panel-search select-empty select-loading select-footer listbox-option listbox-option-check listbox-option-right listbox-group
  autocomplete autocomplete-control autocomplete-input autocomplete-clear autocomplete-panel autocomplete-empty autocomplete-loading
  tags-input tags-input-control tags-input-tag tags-input-tag-remove tags-input-clear tags-input-counter tags-input-empty tags-input-panel
  phone-input phone-box phone-input-control phone-picker phone-clear phone-search phone-empty phone-panel
  filter-menu filter-popup filter-panel filter-footer filter-group filter-sub filter-section filter-separator filter-count filter-option filter-option-input filter-option-text
)
